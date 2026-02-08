
/*
 * Module: AXI_AXIS_AES
 * Author: controlpaths.com (base) / cleaned for synth & AXI compliance
 * Date: 1/29/2026
 *
 * Notes (what was fixed):
 *   - Removed multi-driven register (aw_hs) by using proper internal state
 *     flags for AW and W channels.
 *   - AXI4-Lite compliance improvements:
 *       * AW and W channels are independent (either may arrive first).
 *       * Only one write response outstanding (no accept while BVALID=1).
 *       * Only one read response outstanding (ARREADY deasserted while RVALID=1).
 *       * WSTRB is honored for all RW registers.
 *   - No port/pin name changes.
 */
/*
 * Features:
 *   - AXI4-Lite protocol compliance
 *   - Individual access to RW and RO registers
 *   - Address decoding for up to 17 registers
 *
 * Register Map:
 *   0x00     | RW Register 0
 *   0x04     | RW Register 1
 *   0x08     | RW Register 2
 *   0x0C     | RW Register 3
 *   0x10     | RW Register 4
 *   0x14     | RW Register 5
 *   0x18     | RW Register 6
 *   0x1C     | RW Register 7
 *   0x20     | RW Register 8
 *   0x24     | RW Register 9
 *   0x28     | RW Register 10
 *   0x2C     | RW Register 11
 *   0x30     | RW Register 12
 *   0x34     | RO Register 0
 *   0x38     | RO Register 1
 *   0x3C     | RO Register 2
 *   0x40     | RO Register 3
 */

module AXI_AXIS_AES #(
    parameter integer N = 8
)(
    // Global
    input  wire         clk,
    input  wire         aresetn,

    // AXI4-Lite Slave
    input  wire [31:0]  s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,

    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,

    output wire [1:0]   s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,

    input  wire [31:0]  s_axi_araddr,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,

    output wire [31:0]  s_axi_rdata,
    output wire [1:0]   s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,

    // AXIS Slave
    input  wire [N-1:0] S_AXIS_tdata,
    input  wire         S_AXIS_tlast,
    output wire         S_AXIS_tready,
    input  wire         S_AXIS_tvalid,

    // AXIS Master
    output wire [31:0]  M_AXIS_tdata,
    output wire         M_AXIS_tlast,
    input  wire         M_AXIS_tready,
    output wire         M_AXIS_tvalid
);

    // -------------------------------------------------
    // RW registers (0..12)
    // -------------------------------------------------
    reg [31:0] rw_reg0,  rw_reg1,  rw_reg2,  rw_reg3;
    reg [31:0] rw_reg4,  rw_reg5,  rw_reg6,  rw_reg7;
    reg [31:0] rw_reg8,  rw_reg9,  rw_reg10, rw_reg11;
    reg [31:0] rw_reg12;

    // -------------------------------------------------
    // AXI write channel state
    // -------------------------------------------------
    reg [31:0] awaddr_reg;
    reg        awaddr_valid;

    reg [31:0] wdata_reg;
    reg [3:0]  wstrb_reg;
    reg        wdata_valid;

    reg        bvalid_reg;

    // -------------------------------------------------
    // AXI read channel state
    // -------------------------------------------------
    reg        rvalid_reg;
    reg [31:0] rdata_reg;

    // -------------------------------------------------
    // Helper: apply WSTRB to 32-bit register
    // -------------------------------------------------
    function [31:0] apply_wstrb;
        input [31:0] old_val;
        input [31:0] new_val;
        input [3:0]  st;
        begin
            apply_wstrb = old_val;
            if (st[0]) apply_wstrb[7:0]   = new_val[7:0];
            if (st[1]) apply_wstrb[15:8]  = new_val[15:8];
            if (st[2]) apply_wstrb[23:16] = new_val[23:16];
            if (st[3]) apply_wstrb[31:24] = new_val[31:24];
        end
    endfunction

    // -------------------------------------------------
    // AXI outputs
    // -------------------------------------------------
    assign s_axi_bresp  = 2'b00; // OKAY
    assign s_axi_bvalid = bvalid_reg;
    assign s_axi_rresp  = 2'b00; // OKAY
    assign s_axi_rvalid = rvalid_reg;
    assign s_axi_rdata  = rdata_reg;

    // Only 1 outstanding write + 1 outstanding read supported
    assign s_axi_awready = aresetn && (!awaddr_valid) && (!bvalid_reg);
    assign s_axi_wready  = aresetn && (!wdata_valid)  && (!bvalid_reg);
    assign s_axi_arready = aresetn && (!rvalid_reg);

    // Handshakes
    wire aw_hs = s_axi_awvalid && s_axi_awready;
    wire w_hs  = s_axi_wvalid  && s_axi_wready;
    wire ar_hs = s_axi_arvalid && s_axi_arready;

    // If both address and data are present (latched or handshaking now), do a write.
    wire have_aw = awaddr_valid || aw_hs;
    wire have_w  = wdata_valid  || w_hs;
    wire do_write = have_aw && have_w && (!bvalid_reg);

    // Select current write info: prefer this-cycle handshake values, else latched.
    wire [31:0] write_addr = aw_hs ? s_axi_awaddr : awaddr_reg;
    wire [31:0] write_data = w_hs  ? s_axi_wdata  : wdata_reg;
    wire [3:0]  write_strb = w_hs  ? s_axi_wstrb  : wstrb_reg;

    // -------------------------------------------------
    // Custom AES connections (unchanged)
    // -------------------------------------------------
    wire [255:0] key;
    wire         AES_type_sel;
    wire         AXI_pass;
    wire         AXI_AXIS_Lite;
    wire         AXI_enable;
    wire [127:0] AXI_data_lite_in;
    wire [127:0] AXI_data_lite_out;
    wire         aes_done;

    assign key = {rw_reg1, rw_reg2, rw_reg3, rw_reg4,
                  rw_reg5, rw_reg6, rw_reg7, rw_reg8};

    assign AXI_data_lite_in = {rw_reg9, rw_reg10, rw_reg11, rw_reg12};

    assign AXI_pass      = rw_reg0[0];
    assign AES_type_sel  = rw_reg0[1];
    assign AXI_AXIS_Lite = rw_reg0[2];
    assign AXI_enable    = rw_reg0[3];

    // aes_done rising pulse (used for auto-clearing enable bit)
    reg aes_done_d;
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) aes_done_d <= 1'b0;
        else                aes_done_d <= aes_done;
    end
    wire aes_done_pulse = aes_done & ~aes_done_d;

    // -------------------------------------------------
    // WRITE CHANNEL (AW/W/B)
    // -------------------------------------------------
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            // state
            awaddr_reg   <= 32'd0;
            awaddr_valid <= 1'b0;
            wdata_reg    <= 32'd0;
            wstrb_reg    <= 4'd0;
            wdata_valid  <= 1'b0;
            bvalid_reg   <= 1'b0;

            // regs
            rw_reg0  <= 32'd0;
            rw_reg1  <= 32'd0;
            rw_reg2  <= 32'd0;
            rw_reg3  <= 32'd0;
            rw_reg4  <= 32'd0;
            rw_reg5  <= 32'd0;
            rw_reg6  <= 32'd0;
            rw_reg7  <= 32'd0;
            rw_reg8  <= 32'd0;
            rw_reg9  <= 32'd0;
            rw_reg10 <= 32'd0;
            rw_reg11 <= 32'd0;
            rw_reg12 <= 32'd0;
        end else begin
            // Latch AW if accepted and not immediately consumed by do_write
            if (aw_hs && !do_write) begin
                awaddr_reg   <= s_axi_awaddr;
                awaddr_valid <= 1'b1;
            end

            // Latch W if accepted and not immediately consumed by do_write
            if (w_hs && !do_write) begin
                wdata_reg   <= s_axi_wdata;
                wstrb_reg   <= s_axi_wstrb;
                wdata_valid <= 1'b1;
            end

            // Execute write once we have both address and data (latched or this-cycle)
            if (do_write) begin
                case (write_addr[6:2])
                    5'd0:  rw_reg0  <= apply_wstrb(rw_reg0,  write_data, write_strb);
                    5'd1:  rw_reg1  <= apply_wstrb(rw_reg1,  write_data, write_strb);
                    5'd2:  rw_reg2  <= apply_wstrb(rw_reg2,  write_data, write_strb);
                    5'd3:  rw_reg3  <= apply_wstrb(rw_reg3,  write_data, write_strb);
                    5'd4:  rw_reg4  <= apply_wstrb(rw_reg4,  write_data, write_strb);
                    5'd5:  rw_reg5  <= apply_wstrb(rw_reg5,  write_data, write_strb);
                    5'd6:  rw_reg6  <= apply_wstrb(rw_reg6,  write_data, write_strb);
                    5'd7:  rw_reg7  <= apply_wstrb(rw_reg7,  write_data, write_strb);
                    5'd8:  rw_reg8  <= apply_wstrb(rw_reg8,  write_data, write_strb);
                    5'd9:  rw_reg9  <= apply_wstrb(rw_reg9,  write_data, write_strb);
                    5'd10: rw_reg10 <= apply_wstrb(rw_reg10, write_data, write_strb);
                    5'd11: rw_reg11 <= apply_wstrb(rw_reg11, write_data, write_strb);
                    5'd12: rw_reg12 <= apply_wstrb(rw_reg12, write_data, write_strb);
                    default: begin
                        // unmapped address: no-op
                    end
                endcase

                // consume any latched pieces
                awaddr_valid <= 1'b0;
                wdata_valid  <= 1'b0;

                // generate write response
                bvalid_reg   <= 1'b1;
            end

            // Complete write response
            if (bvalid_reg && s_axi_bready) begin
                bvalid_reg <= 1'b0;
            end

            // Auto-clear enable bit on aes_done (keeps your original behavior)
            if (aes_done_pulse) begin
                rw_reg0[3] <= 1'b0;
            end
        end
    end

    // -------------------------------------------------
    // READ CHANNEL (AR/R)
    // -------------------------------------------------
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            rvalid_reg <= 1'b0;
            rdata_reg  <= 32'd0;
        end else begin
            // Accept a read address only if no response pending
            if (ar_hs) begin
                case (s_axi_araddr[6:2])
                    5'd0:  rdata_reg <= rw_reg0;
                    5'd1:  rdata_reg <= rw_reg1;
                    5'd2:  rdata_reg <= rw_reg2;
                    5'd3:  rdata_reg <= rw_reg3;
                    5'd4:  rdata_reg <= rw_reg4;
                    5'd5:  rdata_reg <= rw_reg5;
                    5'd6:  rdata_reg <= rw_reg6;
                    5'd7:  rdata_reg <= rw_reg7;
                    5'd8:  rdata_reg <= rw_reg8;
                    5'd9:  rdata_reg <= rw_reg9;
                    5'd10: rdata_reg <= rw_reg10;
                    5'd11: rdata_reg <= rw_reg11;
                    5'd12: rdata_reg <= rw_reg12;
                    5'd13: rdata_reg <= AXI_data_lite_out[127:96];
                    5'd14: rdata_reg <= AXI_data_lite_out[95:64];
                    5'd15: rdata_reg <= AXI_data_lite_out[63:32];
                    5'd16: rdata_reg <= AXI_data_lite_out[31:0];
                    default: rdata_reg <= 32'h0;
                endcase
                rvalid_reg <= 1'b1;
            end else if (rvalid_reg && s_axi_rready) begin
                rvalid_reg <= 1'b0;
            end
        end
    end

    // -------------------------------------------------
    // AES + AXIS core
    // -------------------------------------------------
    AES_AXIS #(.N(N)) dut (
        .key(key),
        .AES_type_sel(AES_type_sel),
        .AXI_pass(AXI_pass),
        .AXI_AXIS_Lite(AXI_AXIS_Lite),
        .AXI_enable(AXI_enable),
        .AXI_data_lite_in(AXI_data_lite_in),
        .AXI_data_lite_out(AXI_data_lite_out),
        .aes_done(aes_done),

        .clk(clk),
        .aresetn(aresetn),

        .S_AXIS_tdata(S_AXIS_tdata),
        .S_AXIS_tlast(S_AXIS_tlast),
        .S_AXIS_tready(S_AXIS_tready),
        .S_AXIS_tvalid(S_AXIS_tvalid),

        .M_AXIS_tdata(M_AXIS_tdata),
        .M_AXIS_tlast(M_AXIS_tlast),
        .M_AXIS_tready(M_AXIS_tready),
        .M_AXIS_tvalid(M_AXIS_tvalid)
    );

endmodule
