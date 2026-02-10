`timescale 1ns/1ps

module axi_axis_aes_tb;

    // -------------------------------------------------
    // Parameters
    // -------------------------------------------------
    localparam integer AXI_DATA_WIDTH = 32;
    localparam integer AXI_ADDR_WIDTH = 32;
    localparam integer N = 32;

    // -------------------------------------------------
    // Clock & Reset
    // -------------------------------------------------
    reg S_AXI_clk;
    reg S_AXI_aresetn;

    initial begin
        S_AXI_clk = 0;
        forever #5 S_AXI_clk = ~S_AXI_clk;
    end

    initial begin
        S_AXI_aresetn = 0;
        #50;
        S_AXI_aresetn = 1;
    end

    // -------------------------------------------------
    // AXI-Lite Signals
    // -------------------------------------------------
    reg  [31:0] s_axi_awaddr;
    reg         s_axi_awvalid;
    wire        s_axi_awready;

    reg  [31:0] s_axi_wdata;
    reg  [3:0]  s_axi_wstrb;
    reg         s_axi_wvalid;
    wire        s_axi_wready;

    wire [1:0]  s_axi_bresp;
    wire        s_axi_bvalid;
    reg         s_axi_bready;

    reg  [31:0] s_axi_araddr;
    reg         s_axi_arvalid;
    wire        s_axi_arready;

    wire [31:0] s_axi_rdata;
    wire [1:0]  s_axi_rresp;
    wire        s_axi_rvalid;
    reg         s_axi_rready;

    // -------------------------------------------------
    // AXI-Stream Signals
    // -------------------------------------------------
    reg  [N-1:0] S_AXIS_tdata;
    reg          S_AXIS_tvalid;
    reg          S_AXIS_tlast;
    wire         S_AXIS_tready;

    wire [31:0]  M_AXIS_tdata;
    wire         M_AXIS_tvalid;
    wire         M_AXIS_tlast;
    reg          M_AXIS_tready;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------
    AXI_AXIS_AES #(.N(N)) dut (
        .S_AXI_clk(S_AXI_clk),
        .S_AXI_aresetn(S_AXI_aresetn),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),

        .S_AXIS_tdata(S_AXIS_tdata),
        .S_AXIS_tlast(S_AXIS_tlast),
        .S_AXIS_tready(S_AXIS_tready),
        .S_AXIS_tvalid(S_AXIS_tvalid),

        .M_AXIS_tdata(M_AXIS_tdata),
        .M_AXIS_tlast(M_AXIS_tlast),
        .M_AXIS_tready(M_AXIS_tready),
        .M_AXIS_tvalid(M_AXIS_tvalid)
    );

    // -------------------------------------------------
    // AXI-Lite Write Task
    // -------------------------------------------------
    task axi_write(input [31:0] addr, input [31:0] data);
    begin
        // -------------------------
        // Write Address Channel
        // -------------------------
        @(posedge S_AXI_clk);
        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1;
    
        wait (s_axi_awready);
        @(posedge S_AXI_clk);
        s_axi_awvalid <= 0;
    
        // -------------------------
        // Write Data Channel
        // -------------------------
        s_axi_wdata  <= data;
        s_axi_wstrb <= 4'hF;
        s_axi_wvalid <= 1;
    
        wait (s_axi_wready);
        @(posedge S_AXI_clk);
        s_axi_wvalid <= 0;
    
        // -------------------------
        // Write Response Channel
        // -------------------------
        s_axi_bready <= 1;
        wait (s_axi_bvalid);
        @(posedge S_AXI_clk);
        s_axi_bready <= 0;
    
        $display("[%0t][AXI-W] Addr=0x%08h Data=0x%08h",
                  $time, addr, data);
    end
    endtask

    // -------------------------------------------------
    // AXI-Lite Read Task
    // -------------------------------------------------
    task axi_read(input [31:0] addr);
    begin
        @(posedge S_AXI_clk);
        s_axi_araddr  <= addr;
        s_axi_arvalid <= 1;
    
        wait (s_axi_arready);
        @(posedge S_AXI_clk);
        s_axi_arvalid <= 0;
    
        s_axi_rready <= 1;
        wait (s_axi_rvalid);
    
        $display("[%0t][AXI-R] Addr=0x%08h Data=0x%08h",
                  $time, addr, s_axi_rdata);
    
        @(posedge S_AXI_clk);
        s_axi_rready <= 0;
    end
    endtask

    // -------------------------------------------------
    // AXIS Send Task
    // -------------------------------------------------
    task axis_send(input [N-1:0] data, input last);
    begin
        @(posedge S_AXI_clk);
        S_AXIS_tdata  <= data;
        S_AXIS_tvalid <= 1;
        S_AXIS_tlast  <= last;
        
        /*
        wait (S_AXIS_tready);
        @(posedge S_AXI_clk);
        S_AXIS_tvalid <= 0;
        */
        
    end
    endtask

    // -------------------------------------------------
    // Monitor AXIS Output
    // -------------------------------------------------
    always @(posedge S_AXI_clk) begin
        if (M_AXIS_tvalid && M_AXIS_tready) begin
            $display("[AXIS-OUT] Data=0x%08h Last=%0d",
                     M_AXIS_tdata, M_AXIS_tlast);
        end
    end

    // -------------------------------------------------
    // Test Sequence
    // -------------------------------------------------
    initial begin
        // Defaults
        s_axi_awvalid = 0;
        s_axi_wvalid  = 0;
        s_axi_bready  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;
        S_AXIS_tvalid = 0;
        M_AXIS_tready = 1;

        wait(S_AXI_aresetn);
        
        //AES-128 key -> 00112233445566778899aabbccddeeff
        
        //AES-256 key -> 00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff

        // Configure AES key
        axi_write(32'h04, 32'h00112233);        
        axi_write(32'h08, 32'h44556677);
        axi_write(32'h0C, 32'h8899AABB);
        axi_write(32'h10, 32'hCCDDEEFF);
        
        axi_write(32'h14, 32'h00112233);        
        axi_write(32'h18, 32'h44556677);
        axi_write(32'h1C, 32'h8899AABB);
        axi_write(32'h20, 32'hCCDDEEFF);
        
        // Configure Data
        axi_write(32'h24, 32'h00111111);        
        axi_write(32'h28, 32'h22222222);
        axi_write(32'h2C, 32'h33333333);
        axi_write(32'h30, 32'h44444444);
        
        // Configure register
        axi_write(32'h00, 32'd6);
        axi_write(32'h00, 32'd14);
        
        // Read output block
        axi_read(32'h34);
        axi_read(32'h38);
        axi_read(32'h3C);
        axi_read(32'h40);
        
        // Configure Data
        axi_write(32'h24, 32'hFFFFFFFF);        
        axi_write(32'h28, 32'h22222222);
        axi_write(32'h2C, 32'h33333333);
        axi_write(32'h30, 32'h44444444);
        
        // Configure register
        axi_write(32'h00, 32'd6);
        axi_write(32'h00, 32'd14);

        // Read output block
        axi_read(32'h34);
        axi_read(32'h38);
        axi_read(32'h3C);
        axi_read(32'h40);
        
        // Configure Data
        axi_write(32'h24, 32'hEEEEEEEE);        
        axi_write(32'h28, 32'h22222222);
        axi_write(32'h2C, 32'h33333333);
        axi_write(32'h30, 32'h44444444);
        
        // Configure register
        axi_write(32'h00, 32'd6);
        axi_write(32'h00, 32'd14);

        // Read output block
        axi_read(32'h34);
        axi_read(32'h38);
        axi_read(32'h3C);
        axi_read(32'h40);


        //Enable AXI Stream Interface
        axi_write(32'h00, 32'h00000002);

        // Send AXIS data
        axis_send(8'hAA, 0);
        axis_send(8'hBB, 0);
        axis_send(8'hCC, 0);
        axis_send(8'hAA, 0);
        
        axis_send(8'hBB, 0);
        axis_send(8'hCC, 0);
        axis_send(8'hAA, 0);
        axis_send(8'hBB, 0);
        
        axis_send(8'hCC, 0);
        axis_send(8'hAA, 0);
        axis_send(8'hBB, 0);
        axis_send(8'hCC, 0);
        
        axis_send(8'hAA, 0);
        axis_send(8'hBB, 0);
        axis_send(8'hCC, 0);
        axis_send(8'hCC, 0);
        
        for (int i = 0; i < 1000; i++)
            axis_send($random, 0);

        #100;


        #200;
        $display("---- TEST COMPLETE ----");
        $finish;
    end

endmodule