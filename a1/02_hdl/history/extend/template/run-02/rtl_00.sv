module extend (
    input  logic [31:7] InstrD,
    input  logic [2:0]  ImmSrcD,
    output logic [31:0] ImmExtD
);

    logic [31:0] imm_i;
    logic [31:0] imm_s;
    logic [31:0] imm_b;
    logic [31:0] imm_j;
    logic [31:0] imm_u;

    always_comb begin
        imm_i = {{20{InstrD[31]}}, InstrD[31:20]};
        imm_s = {{20{InstrD[31]}}, InstrD[31:25], InstrD[11:7]};
        imm_b = {{20{InstrD[31]}}, InstrD[7], InstrD[30:25], InstrD[11:8], 1'b0};
        imm_j = {{12{InstrD[31]}}, InstrD[19:12], InstrD[20], InstrD[30:21], 1'b0};
        imm_u = {InstrD[31:12], 12'b0};

        ImmExtD = 32'b0;
        case (ImmSrcD)
            3'b000: ImmExtD = imm_i;
            3'b001: ImmExtD = imm_s;
            3'b010: ImmExtD = imm_b;
            3'b011: ImmExtD = imm_j;
            3'b100: ImmExtD = imm_u;
            default: ImmExtD = 32'b0;
        endcase
    end

endmodule
