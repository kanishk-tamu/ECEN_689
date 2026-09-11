module alu (
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [2:0]  ALUSelect,
    input  logic        SubArith,
    output logic [31:0] ALUResult,
    output logic [31:0] Sum
);

    always_comb begin
        if (SubArith) begin
            Sum = A - B;
        end else begin
            Sum = A + B;
        end

        case (ALUSelect)
            3'b000: begin
                ALUResult = Sum;
            end
            3'b001: begin
                ALUResult = A << B[4:0];
            end
            3'b010: begin
                if (SubArith) begin
                    ALUResult = ($signed(A) < $signed(B)) ? 32'h00000001 : 32'h00000000;
                end else begin
                    ALUResult = 32'h00000000;
                end
            end
            3'b011: begin
                if (SubArith) begin
                    ALUResult = (A < B) ? 32'h00000001 : 32'h00000000;
                end else begin
                    ALUResult = 32'h00000000;
                end
            end
            3'b100: begin
                ALUResult = A ^ B;
            end
            3'b101: begin
                if (SubArith) begin
                    ALUResult = $signed(A) >>> B[4:0];
                end else begin
                    ALUResult = A >> B[4:0];
                end
            end
            3'b110: begin
                ALUResult = A | B;
            end
            3'b111: begin
                ALUResult = A & B;
            end
            default: begin
                ALUResult = 32'h00000000;
            end
        endcase
    end

endmodule
