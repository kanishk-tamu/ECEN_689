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
    logic        slt_true;
    logic        sltu_true;
    logic signed [31:0] A_signed;
    logic signed [31:0] B_signed;

    always_comb begin
        shamt      = B[4:0];
        A_signed   = A;
        B_signed   = B;
        add_result = A + B;
        sub_result = A - B;
        slt_true   = (A_signed < B_signed);
        sltu_true  = (A < B);

        if (SubArith) begin
            Sum = sub_result;
        end else begin
            Sum = add_result;
        end

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
                    ALUResult = A << shamt;
                end else begin
                    ALUResult = 32'h00000000;
                end
            end

            3'b010: begin
                if (SubArith) begin
                    ALUResult = {31'b0, slt_true};
                end else begin
                    ALUResult = 32'h00000000;
                end
            end

            3'b011: begin
                if (SubArith) begin
                    ALUResult = {31'b0, sltu_true};
                end else begin
                    ALUResult = 32'h00000000;
                end
            end

            3'b100: begin
                if (!SubArith) begin
                    ALUResult = A ^ B;
                end else begin
                    ALUResult = 32'h00000000;
                end
            end

            3'b101: begin
                if (SubArith) begin
                    ALUResult = A_signed >>> shamt;
                end else begin
                    ALUResult = A >> shamt;
                end
            end

            3'b110: begin
                if (!SubArith) begin
                    ALUResult = A | B;
                end else begin
                    ALUResult = 32'h00000000;
                end
            end

            3'b111: begin
                if (!SubArith) begin
                    ALUResult = A & B;
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
