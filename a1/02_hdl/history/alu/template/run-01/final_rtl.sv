module alu (
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [2:0]  ALUSelect,
    input  logic        SubArith,
    output logic [31:0] ALUResult,
    output logic [31:0] Sum
);

    logic [4:0]  shamt;
    logic [31:0] add_result;
    logic [31:0] sub_result;
    logic [31:0] sll_result;
    logic [31:0] srl_result;
    logic [31:0] sra_result;
    logic [31:0] xor_result;
    logic [31:0] or_result;
    logic [31:0] and_result;
    logic [31:0] slt_result;
    logic [31:0] sltu_result;

    assign shamt       = B[4:0];
    assign add_result  = A + B;
    assign sub_result  = A - B;
    assign sll_result  = A << shamt;
    assign srl_result  = A >> shamt;
    assign sra_result  = $signed(A) >>> shamt;
    assign xor_result  = A ^ B;
    assign or_result   = A | B;
    assign and_result  = A & B;
    assign slt_result  = ($signed(A) < $signed(B)) ? 32'h00000001 : 32'h00000000;
    assign sltu_result = (A < B) ? 32'h00000001 : 32'h00000000;

    always_comb begin
        Sum = 32'h00000000;
        if (SubArith) begin
            Sum = sub_result;
        end else begin
            Sum = add_result;
        end
    end

    always_comb begin
        ALUResult = 32'h00000000;

        case (ALUSelect)
            3'b000: begin
                if (SubArith) begin
                    ALUResult = sub_result;
                end else begin
                    ALUResult = add_result;
                end
            end

            3'b001: begin
                if (!SubArith) begin
                    ALUResult = sll_result;
                end else begin
                    ALUResult = 32'h00000000;
                end
            end

            3'b010: begin
                if (SubArith) begin
                    ALUResult = slt_result;
                end else begin
                    ALUResult = 32'h00000000;
                end
            end

            3'b011: begin
                if (SubArith) begin
                    ALUResult = sltu_result;
                end else begin
                    ALUResult = 32'h00000000;
                end
            end

            3'b100: begin
                if (!SubArith) begin
                    ALUResult = xor_result;
                end else begin
                    ALUResult = 32'h00000000;
                end
            end

            3'b101: begin
                if (SubArith) begin
                    ALUResult = sra_result;
                end else begin
                    ALUResult = srl_result;
                end
            end

            3'b110: begin
                if (!SubArith) begin
                    ALUResult = or_result;
                end else begin
                    ALUResult = 32'h00000000;
                end
            end

            3'b111: begin
                if (!SubArith) begin
                    ALUResult = and_result;
                end else begin
                    ALUResult = 32'h00000000;
                end
            end

            default: begin
                ALUResult = 32'h00000000;
            end
        endcase
    end

endmodule
