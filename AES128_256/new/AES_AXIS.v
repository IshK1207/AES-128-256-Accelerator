`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Viscypta Technologies
// Engineer: Shayan Ahmad
//
// AES_AXIS
//
// Notes on changes (functional intent preserved):
//   * AXI-Stream Master interface is made protocol-correct:
//       - TDATA/TLAST are valid whenever TVALID=1 and remain stable while
//         TVALID=1 & TREADY=0 (backpressure).
//       - Internal out_word_idx advances ONLY on TVALID&TREADY handshake.
//   * No changes to pin names.
//   * AXI-Lite mode keeps a single 128-bit buffer (lite_data) sampled while
//     AXI_enable is asserted.
//////////////////////////////////////////////////////////////////////////////////


module AES_AXIS #(
    parameter integer N = 8   // N should be {128, 64, 32, 16, 8}
)
(
//------------ AES Core Logic ------------//
    input     [255:0]     key,
    input                 AES_type_sel,           // Type selection between AES128/256
    input                 AXI_pass,               // If enable it acts as simple passthrough module
    input                 AXI_AXIS_Lite,          // Choose between which data encrypt AXI Stream or AXI_data_in
    input                 AXI_enable,
    input      [127:0]    AXI_data_lite_in,
    output reg [127:0]    AXI_data_lite_out,
    
    output                aes_done,

//------------ Global Signal ------------//
    input                 clk,
    input                 aresetn,

//------------ AXIS Slave Signal ------------//
    input  [N-1:0]        S_AXIS_tdata,
    input                 S_AXIS_tlast,
    output                S_AXIS_tready,
    input                 S_AXIS_tvalid,

//------------ AXIS Master Signal ------------//    
    output reg [31:0]     M_AXIS_tdata,
    output reg            M_AXIS_tlast,
    input                 M_AXIS_tready,
    output reg            M_AXIS_tvalid
);

    // =============================================================
    // Packing params
    // =============================================================
    localparam integer N_param = 128 / N;
    localparam integer N_log   = (N_param > 1) ? $clog2(N_param) : 1;

    // =============================================================
    // AXIS assembler (N-bit beats -> 128-bit)
    // =============================================================
    reg [N_log-1:0] axis_beat_idx;
    reg [127:0]     axis_assemble_block;
    reg [127:0]     axis_block_next;

    wire s_axis_accept = S_AXIS_tvalid && S_AXIS_tready;

    always @(*) begin
        axis_block_next = axis_assemble_block;
        if (s_axis_accept)
            axis_block_next[127 - (N * axis_beat_idx) -: N] = S_AXIS_tdata;
    end

    wire axis_block_complete = s_axis_accept && (axis_beat_idx == (N_param-1));

    // =============================================================
    // 2-slot INPUT block buffer (FFs)
    // =============================================================
    reg [127:0] in0_data, in1_data;
    reg         in0_last, in1_last;
    reg         in0_valid, in1_valid;

    wire in_full = in0_valid & in1_valid;

    // Stream ready only when not in AXI-Lite mode and input slots not full
    assign S_AXIS_tready = aresetn && !AXI_AXIS_Lite && !in_full;

    // =============================================================
    // 2-slot OUTPUT block buffer (FFs)
    // =============================================================
    reg [127:0] out0_data, out1_data;
    reg         out0_last, out1_last;
    reg         out0_valid, out1_valid;

    wire out_full = out0_valid & out1_valid;

    // Push into first empty slot (out0 then out1)
    task push_output_slot;
        input [127:0] data_in;
        input         last_in;
        begin
            if (!out0_valid) begin
                out0_data  <= data_in;
                out0_last  <= last_in;
                out0_valid <= 1'b1;
            end else if (!out1_valid) begin
                out1_data  <= data_in;
                out1_last  <= last_in;
                out1_valid <= 1'b1;
            end
        end
    endtask

    // Pop slot0 and shift slot1->slot0
    task pop_shift_output;
        begin
            if (out1_valid) begin
                out0_data  <= out1_data;
                out0_last  <= out1_last;
                out0_valid <= 1'b1;
                out1_valid <= 1'b0;
            end else begin
                out0_valid <= 1'b0;
            end
        end
    endtask

    // =============================================================
    // AXI-Lite SINGLE BUFFER
    // =============================================================
    reg        lite_valid;
    reg [127:0] lite_data;

    // Sample AXI-Lite data while enabled
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            lite_valid <= 1'b0;
            lite_data  <= 128'd0;
        end else if (AXI_AXIS_Lite && AXI_enable) begin
            lite_valid <= 1'b1;
            lite_data  <= AXI_data_lite_in;
        end else begin
            lite_valid <= 1'b0;
        end
    end

    // =============================================================
    // AES CONTROL (single in-flight)
    // =============================================================
    reg         aes_busy;
    reg         aes_enable_pulse;
    reg [127:0] AES_plaintext_data;
    reg         pending_last;

    wire [127:0] AES_data_out;

    // aes_done edge detect
    reg  aes_done_d;
    wire aes_done_pulse;

    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) aes_done_d <= 1'b0;
        else          aes_done_d <= aes_done;
    end
    assign aes_done_pulse = aes_done & ~aes_done_d;

    // AXI-Lite output register update
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn)
            AXI_data_lite_out <= 128'd0;
        else if (aes_done_pulse)
            AXI_data_lite_out <= AES_data_out;
    end

    // Start conditions
    wire can_start_encrypt_stream =
        (!AXI_AXIS_Lite) && (!AXI_pass) &&
        in0_valid && (!aes_busy) && (!out_full);

    // NOTE: No out_full gating here by design (AXI-Lite output is separate).
    wire can_start_encrypt_lite =
        (AXI_AXIS_Lite) && (AXI_enable) && (lite_valid) && (!aes_busy) && (!AXI_pass);

    wire can_start_bypass =
        (AXI_pass) && in0_valid && (!out_full);

    // Consume stream input slot0 when starting bypass or stream-encrypt
    wire consume_stream_in0 = can_start_bypass || can_start_encrypt_stream;

    // =============================================================
    // AXIS Master handshake tracking
    // =============================================================
    reg  [1:0] out_word_idx;

    // Protocol-correct: advance ONLY on TVALID&TREADY
    wire m_axis_accept = M_AXIS_tvalid && M_AXIS_tready;

    // =============================================================
    // Main sequential logic
    // =============================================================
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            axis_beat_idx       <= {N_log{1'b0}};
            axis_assemble_block <= 128'd0;

            in0_valid <= 1'b0;
            in1_valid <= 1'b0;
            in0_last  <= 1'b0;
            in1_last  <= 1'b0;

            out0_valid <= 1'b0;
            out1_valid <= 1'b0;
            out0_last  <= 1'b0;
            out1_last  <= 1'b0;

            aes_busy         <= 1'b0;
            aes_enable_pulse <= 1'b0;
            AES_plaintext_data <= 128'd0;
            pending_last     <= 1'b0;

            out_word_idx <= 2'd0;
        end else begin
            // defaults
            aes_enable_pulse <= 1'b0;

            // ----------------------------
            // AXIS assembler update
            // ----------------------------
            if (!AXI_AXIS_Lite && s_axis_accept) begin
                if (axis_beat_idx == (N_param-1)) begin
                    axis_beat_idx       <= {N_log{1'b0}};
                    axis_assemble_block <= 128'd0;
                end else begin
                    axis_beat_idx       <= axis_beat_idx + 1'b1;
                    axis_assemble_block <= axis_block_next;
                end
            end

            // Push completed 128b block into input buffer
            if (!AXI_AXIS_Lite && axis_block_complete) begin
                if (!in0_valid) begin
                    in0_data  <= axis_block_next;
                    in0_last  <= S_AXIS_tlast;
                    in0_valid <= 1'b1;
                end else if (!in1_valid) begin
                    in1_data  <= axis_block_next;
                    in1_last  <= S_AXIS_tlast;
                    in1_valid <= 1'b1;
                end
            end

            // ----------------------------
            // BYPASS: move input block to output buffer
            // ----------------------------
            if (can_start_bypass) begin
                push_output_slot(in0_data, in0_last);
            end

            // ----------------------------
            // STREAM ENCRYPT: start AES on in0
            // ----------------------------
            if (can_start_encrypt_stream) begin
                AES_plaintext_data <= in0_data;
                pending_last       <= in0_last;
                aes_enable_pulse   <= 1'b1;
                aes_busy           <= 1'b1;
            end

            // ----------------------------
            // LITE ENCRYPT: start AES on lite_data
            // ----------------------------
            if (can_start_encrypt_lite) begin
                AES_plaintext_data <= lite_data;
                pending_last       <= 1'b1;
                aes_enable_pulse   <= 1'b1;
                aes_busy           <= 1'b1;
            end

            // ----------------------------
            // Consume stream input slot0 on start
            // ----------------------------
            if (consume_stream_in0) begin
                if (in1_valid) begin
                    in0_data  <= in1_data;
                    in0_last  <= in1_last;
                    in0_valid <= 1'b1;
                    in1_valid <= 1'b0;
                end else begin
                    in0_valid <= 1'b0;
                    in0_last  <= 1'b0;
                end
            end

            // ----------------------------
            // AES completion: push result to output buffer
            // (busy clears regardless of AXI_pass to avoid lockup
            //  if AXI_pass is toggled mid-operation)
            // ----------------------------
            if (aes_done_pulse && aes_busy) begin
                push_output_slot(AES_data_out, pending_last);
                aes_busy <= 1'b0;
            end

            // ----------------------------
            // AXIS Master: advance/pop ONLY on handshake
            // ----------------------------
            if (out0_valid) begin
                if (m_axis_accept) begin
                    if (out_word_idx == 2'd3) begin
                        out_word_idx <= 2'd0;
                        pop_shift_output();
                    end else begin
                        out_word_idx <= out_word_idx + 1'b1;
                    end
                end
            end else begin
                out_word_idx <= 2'd0;
            end
        end
    end

    // =============================================================
    // AXI-Stream Master outputs (protocol-correct)
    //   - Valid/data/last reflect current out0 slot & word index
    //   - Stable under backpressure because out_word_idx changes only
    //     on m_axis_accept.
    // =============================================================
    always @(*) begin
        M_AXIS_tvalid = out0_valid;
        M_AXIS_tdata  = 32'd0;
        M_AXIS_tlast  = 1'b0;

        if (out0_valid) begin
            case (out_word_idx)
                2'd0: M_AXIS_tdata = out0_data[127:96];
                2'd1: M_AXIS_tdata = out0_data[95:64];
                2'd2: M_AXIS_tdata = out0_data[63:32];
                2'd3: M_AXIS_tdata = out0_data[31:0];
                default: M_AXIS_tdata = out0_data[127:96];
            endcase
            M_AXIS_tlast = out0_last && (out_word_idx == 2'd3);
        end
    end

    // =============================================================
    // AES core instance (unchanged)
    // =============================================================
    encrypt_aes aes_inst (
        .in      (AES_plaintext_data),
        .key     (key),
        .clk     (clk),
        .enable  (aes_enable_pulse),
        .type    (AES_type_sel),
        .reset_n (aresetn),
        .out     (AES_data_out),
        .done    (aes_done)
    );

endmodule
