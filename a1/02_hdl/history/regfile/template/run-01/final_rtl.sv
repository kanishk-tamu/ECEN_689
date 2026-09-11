module regfile (
    input  logic        clk,
    input  logic        reset,
    input  logic        we3,
    input  logic [4:0]  a1,
    input  logic [4:0]  a2,
    input  logic [4:0]  a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);

    logic [31:0] regs [31:0];
    integer i;

    logic a1_is_zero;
    logic a2_is_zero;
    logic a3_is_zero;
    logic write_valid;

    assign a1_is_zero = (a1 == 5'd0);
    assign a2_is_zero = (a2 == 5'd0);
    assign a3_is_zero = (a3 == 5'd0);
    assign write_valid = we3 && !a3_is_zero;

    always_comb begin
        rd1 = 32'h00000000;
        rd2 = 32'h00000000;

        if (!a1_is_zero) begin
            rd1 = regs[a1];
        end

        if (!a2_is_zero) begin
            rd2 = regs[a2];
        end
    end

    always_ff @(negedge clk) begin
        if (reset) begin
            regs[0] <= 32'h00000000;
            for (i = 1; i < 32; i = i + 1) begin
                regs[i] <= 32'h00000000;
            end
        end else begin
            regs[0] <= 32'h00000000;
            if (write_valid) begin
                regs[a3] <= wd3;
            end
        end
    end

endmodule
