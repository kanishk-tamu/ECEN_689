module controller (
    input  logic [31:0] InstrD,
    output logic        RegWriteD,
    output logic [2:0]  ImmSrcD,
    output logic        ALUSrcAD,
    output logic        ALUSrcBD,
    output logic [1:0]  MemRWD,
    output logic [2:0]  ResultSrcD,
    output logic        BranchD,
    output logic        JumpD,
    output logic        ALUResultSrcD,
    output logic [2:0]  ALUSelectD,
    output logic        SubArithD,
    output logic        IllegalInstrD
);

    logic [6:0] opcode;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;

    logic legal_load;
    logic legal_store;
    logic legal_branch;
    logic legal_jalr;
    logic legal_rtype;
    logic legal_itype;
    logic legal_instr;

    logic rtype_funct7_ok;
    logic is_shift_imm;
    logic itype_shift_ok;
    logic itype_nonshift_ok;

    assign opcode = InstrD[6:0];
    assign rd     = InstrD[11:7];
    assign funct3 = InstrD[14:12];
    assign rs1    = InstrD[19:15];
    assign rs2    = InstrD[24:20];
    assign funct7 = InstrD[31:25];

    always_comb begin
        rd = InstrD[11:7];
        rs1 = InstrD[19:15];
        rs2 = InstrD[24:20];

        legal_load       = 1'b0;
        legal_store      = 1'b0;
        legal_branch     = 1'b0;
        legal_jalr       = 1'b0;
        legal_rtype      = 1'b0;
        legal_itype      = 1'b0;
        legal_instr      = 1'b0;
        rtype_funct7_ok  = 1'b0;
        is_shift_imm     = 1'b0;
        itype_shift_ok   = 1'b0;
        itype_nonshift_ok = 1'b0;

        RegWriteD      = 1'b0;
        ImmSrcD        = 3'b000;
        ALUSrcAD       = 1'b0;
        ALUSrcBD       = 1'b0;
        MemRWD         = 2'b00;
        ResultSrcD     = 3'b000;
        BranchD        = 1'b0;
        JumpD          = 1'b0;
        ALUResultSrcD  = 1'b0;
        ALUSelectD     = 3'b000;
        SubArithD      = 1'b0;
        IllegalInstrD  = 1'b0;

        legal_load   = (funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010) ||
                       (funct3 == 3'b100) || (funct3 == 3'b101);

        legal_store  = (funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010);

        legal_branch = (funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b100) ||
                       (funct3 == 3'b101) || (funct3 == 3'b110) || (funct3 == 3'b111);

        legal_jalr   = (funct3 == 3'b000);

        case (funct3)
            3'b000: rtype_funct7_ok = (funct7 == 7'b0000000) || (funct7 == 7'b0100000);
            3'b001: rtype_funct7_ok = (funct7 == 7'b0000000);
            3'b010: rtype_funct7_ok = (funct7 == 7'b0000000);
            3'b011: rtype_funct7_ok = (funct7 == 7'b0000000);
            3'b100: rtype_funct7_ok = (funct7 == 7'b0000000);
            3'b101: rtype_funct7_ok = (funct7 == 7'b0000000) || (funct7 == 7'b0100000);
            3'b110: rtype_funct7_ok = (funct7 == 7'b0000000);
            3'b111: rtype_funct7_ok = (funct7 == 7'b0000000);
            default: rtype_funct7_ok = 1'b0;
        endcase
        legal_rtype = rtype_funct7_ok;

        is_shift_imm      = (funct3 == 3'b001) || (funct3 == 3'b101);
        itype_shift_ok    = ((funct3 == 3'b001) && (funct7 == 7'b0000000)) ||
                            ((funct3 == 3'b101) && ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)));
        itype_nonshift_ok = (funct3 == 3'b000) || (funct3 == 3'b010) || (funct3 == 3'b011) ||
                            (funct3 == 3'b100) || (funct3 == 3'b110) || (funct3 == 3'b111);
        if (is_shift_imm) begin
            legal_itype = itype_shift_ok;
        end else begin
            legal_itype = itype_nonshift_ok;
        end

        case (opcode)
            7'b0000011: begin
                RegWriteD      = 1'b1;
                ImmSrcD        = 3'b000;
                ALUSrcAD       = 1'b0;
                ALUSrcBD       = 1'b1;
                MemRWD         = 2'b10;
                ResultSrcD     = 3'b001;
                BranchD        = 1'b0;
                JumpD          = 1'b0;
                ALUResultSrcD  = 1'b0;
                ALUSelectD     = 3'b000;
                SubArithD      = 1'b0;
                legal_instr    = legal_load;
            end

            7'b0010011: begin
                RegWriteD      = 1'b1;
                ImmSrcD        = 3'b000;
                ALUSrcAD       = 1'b0;
                ALUSrcBD       = 1'b1;
                MemRWD         = 2'b00;
                ResultSrcD     = 3'b000;
                BranchD        = 1'b0;
                JumpD          = 1'b0;
                ALUResultSrcD  = 1'b0;
                ALUSelectD     = funct3;
                SubArithD      = (funct3 == 3'b010) || (funct3 == 3'b011) ||
                                 ((funct3 == 3'b101) && (funct7 == 7'b0100000));
                legal_instr    = legal_itype;
            end

            7'b0010111: begin
                RegWriteD      = 1'b1;
                ImmSrcD        = 3'b100;
                ALUSrcAD       = 1'b1;
                ALUSrcBD       = 1'b1;
                MemRWD         = 2'b00;
                ResultSrcD     = 3'b000;
                BranchD        = 1'b0;
                JumpD          = 1'b0;
                ALUResultSrcD  = 1'b0;
                ALUSelectD     = 3'b000;
                SubArithD      = 1'b0;
                legal_instr    = 1'b1;
            end

            7'b0100011: begin
                RegWriteD      = 1'b0;
                ImmSrcD        = 3'b001;
                ALUSrcAD       = 1'b0;
                ALUSrcBD       = 1'b1;
                MemRWD         = 2'b01;
                ResultSrcD     = 3'b000;
                BranchD        = 1'b0;
                JumpD          = 1'b0;
                ALUResultSrcD  = 1'b0;
                ALUSelectD     = 3'b000;
                SubArithD      = 1'b0;
                legal_instr    = legal_store;
            end

            7'b0110011: begin
                RegWriteD      = 1'b1;
                ImmSrcD        = 3'b000;
                ALUSrcAD       = 1'b0;
                ALUSrcBD       = 1'b0;
                MemRWD         = 2'b00;
                ResultSrcD     = 3'b000;
                BranchD        = 1'b0;
                JumpD          = 1'b0;
                ALUResultSrcD  = 1'b0;
                ALUSelectD     = funct3;
                SubArithD      = (funct3 == 3'b010) || (funct3 == 3'b011) ||
                                 ((funct3 == 3'b000) && (funct7 == 7'b0100000)) ||
                                 ((funct3 == 3'b101) && (funct7 == 7'b0100000));
                legal_instr    = legal_rtype;
            end

            7'b0110111: begin
                RegWriteD      = 1'b1;
                ImmSrcD        = 3'b100;
                ALUSrcAD       = 1'b0;
                ALUSrcBD       = 1'b1;
                MemRWD         = 2'b00;
                ResultSrcD     = 3'b000;
                BranchD        = 1'b0;
                JumpD          = 1'b0;
                ALUResultSrcD  = 1'b1;
                ALUSelectD     = 3'b000;
                SubArithD      = 1'b0;
                legal_instr    = 1'b1;
            end

            7'b1100011: begin
                RegWriteD      = 1'b0;
                ImmSrcD        = 3'b010;
                ALUSrcAD       = 1'b1;
                ALUSrcBD       = 1'b1;
                MemRWD         = 2'b00;
                ResultSrcD     = 3'b000;
                BranchD        = 1'b1;
                JumpD          = 1'b0;
                ALUResultSrcD  = 1'b0;
                ALUSelectD     = 3'b000;
                SubArithD      = 1'b0;
                legal_instr    = legal_branch;
            end

            7'b1100111: begin
                RegWriteD      = 1'b1;
                ImmSrcD        = 3'b000;
                ALUSrcAD       = 1'b0;
                ALUSrcBD       = 1'b1;
                MemRWD         = 2'b00;
                ResultSrcD     = 3'b000;
                BranchD        = 1'b0;
                JumpD          = 1'b1;
                ALUResultSrcD  = 1'b1;
                ALUSelectD     = 3'b000;
                SubArithD      = 1'b0;
                legal_instr    = legal_jalr;
            end

            7'b1101111: begin
                RegWriteD      = 1'b1;
                ImmSrcD        = 3'b011;
                ALUSrcAD       = 1'b1;
                ALUSrcBD       = 1'b1;
                MemRWD         = 2'b00;
                ResultSrcD     = 3'b000;
                BranchD        = 1'b0;
                JumpD          = 1'b1;
                ALUResultSrcD  = 1'b1;
                ALUSelectD     = 3'b000;
                SubArithD      = 1'b0;
                legal_instr    = 1'b1;
            end

            default: begin
                legal_instr    = 1'b0;
            end
        endcase

        IllegalInstrD = ~legal_instr;

        if (IllegalInstrD) begin
            RegWriteD      = 1'b0;
            ImmSrcD        = 3'b000;
            ALUSrcAD       = 1'b0;
            ALUSrcBD       = 1'b0;
            MemRWD         = 2'b00;
            ResultSrcD     = 3'b000;
            BranchD        = 1'b0;
            JumpD          = 1'b0;
            ALUResultSrcD  = 1'b0;
            ALUSelectD     = 3'b000;
            SubArithD      = 1'b0;
        end
    end

endmodule
