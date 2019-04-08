#!/usr/bin/env python3

import sys

# Define control signals: 32 bits
# -------------------------
# Name          Size (bits)
# -------------------------
# invalid:      1
# is_muldiv:    1
# fence_i:      1
# xcall_xbreak: 1
# regfile_we:   1
# is_jump:      1
# branch_type:  6
# csr_cmd:      2
# mem_rw:       1
# mem_en:       1
# alu_type:     2
# alu_cmp:      1
# alu_shift:    1
# alu_logic:    2
# alu_add:      1
# sel_wb_data:  2
# sel_imm:      3
# sel_opB:      2
# sel_opA:      2

#               Fields
#               -*-*-*------**-*--*-**-**---**--
lui          = '00001000000000000000000000110111'
auipc        = '00001000000000000000000000110101'
jal          = '00001100000000000000000111000101'
jalr         = '00001100000000000000000110000100'
beq          = '00000000000100000000000000100101'
bne          = '00000000001000000000000000100101'
blt          = '00000000010000000000000000100101'
bge          = '00000000100000000000000000100101'
bltu         = '00000001000000000000000000100101'
bgeu         = '00000010000000000000000000100101'
lb           = '00001000000000010000000010000100'
lh           = '00001000000000010000000010000100'
lw           = '00001000000000010000000010000100'
lbu          = '00001000000000010000000010000100'
lhu          = '00001000000000010000000010000100'
sb           = '00000000000000110000000000010100'
sh           = '00000000000000110000000000010100'
sw           = '00000000000000110000000000010100'
addi         = '00001000000000000000000000000100'
slti         = '00001000000000001110000000000100'
sltiu        = '00001000000000001100000000000100'
xori         = '00001000000000000100100000000100'
ori          = '00001000000000000100010000000100'
andi         = '00001000000000000100000000000100'
slli         = '00001000000000001000000000000100'
srli_srai    = '00001000000000001001000000000100'
add_sub      = '00001000000000000000001000000000'
sll          = '00001000000000001000000000000000'
slt          = '00001000000000001110000000000000'
sltu         = '00001000000000001100000000000000'
xor          = '00001000000000000100100000000000'
srl_sra      = '00001000000000001001000000000000'
or_          = '00001000000000000100010000000000'
and_         = '00001000000000000100000000000000'
fence        = '00000000000000000000000000000000'
fence_i      = '00100000000000000000000000000000'
ecall_ebreak = '00010000000000000000000000000000'
csrrw        = '00001000000001000000000100001100'
csrrs        = '00001000000010000000000100001100'
csrrc        = '00001000000011000000000100001100'
csrrwi       = '00001000000001000000000100001100'
csrrsi       = '00001000000010000000000100001100'
csrrci       = '00001000000011000000000100001100'
muldiv       = '01001000000000000000000000000000'
invalid      = '10000000000000000000000000000000'

# group for class
g0  = [lui for _ in range(8)]
g1  = [auipc for _ in range(8)]
g2  = [jal for _ in range(8)]
g3  = [jalr for _ in range(8)]
g4  = [beq, bne, invalid, invalid, blt, bge, bltu, bgeu]
g5  = [lb, lh, lw, invalid, lbu, lhu, invalid, invalid]
g6  = [sb, sh, sw, invalid, invalid, invalid, invalid, invalid]
g7  = [addi, slli, slti, sltiu, xori, srli_srai, ori, andi]
g8  = [add_sub, sll , slt , sltu, xor , srl_sra , or_, and_]
g9  = [fence, fence_i, invalid, invalid, invalid, invalid, invalid, invalid]
g10 = [ecall_ebreak, csrrw, csrrs, csrrc, invalid, csrrwi, csrrsi, csrrci]
g11 = [muldiv for _ in range (8)]
g12 = [invalid for _ in range (8)]
g13 = [invalid for _ in range (8)]
g14 = [invalid for _ in range (8)]
g15 = [invalid for _ in range (8)]
opcode_class = [g0, g1, g2, g3, g4, g5, g6, g7,
                g8, g9, g10, g11, g12, g13, g14, g15]

def generate(filename):
    with open(filename, 'w') as f:
        f.write('// Mirfak control signals\n')
        for group in opcode_class:
            for instr in group:
                f.write(instr + '\n')

if __name__ == '__main__':
    print('[MIRFAK] Generating {}'.format(sys.argv[1]))
    generate(sys.argv[1])
    print('[MIRFAK] Generation DONE')
