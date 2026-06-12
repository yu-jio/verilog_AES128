# Verilog AES-128

AES-128 encryption and decryption implemented in Verilog, with a C reference
file and a Verilog testbench for validating the standard AES test vector.

## Project Contents

| File | Description |
| --- | --- |
| `AES_128.v` | Top-level Verilog AES-128 implementation |
| `stimulus.v` | Simulation testbench |
| `AES-128.c` | C reference implementation |
| `README.md` | Design notes, datapath summary, FSM, waveform results, and synthesis notes |

## Interface

### Inputs

| Signal | Width | Description |
| --- | --- | --- |
| `clk` | 1 bit | Clock signal |
| `nrst` | 1 bit | Asynchronous reset |
| `encdec` | 1 bit | Encryption/decryption select: `1` for encryption, `0` for decryption |
| `start` | 1 bit | Starts an AES operation |
| `key` | 128 bits | AES-128 key |
| `textin` | 128 bits | Plaintext or ciphertext input |

### Outputs

| Signal | Width | Description |
| --- | --- | --- |
| `done` | 1 bit | Operation complete flag |
| `textout` | 128 bits | Encrypted or decrypted output |

## AES Datapath

The implementation follows the AES-128 round structure with 10 rounds.

- `AddRoundKey`: XORs the current state with the round key
- `SubBytes` / `InvSubBytes`: S-box substitution for encryption/decryption
- `ShiftRows` / `InvShiftRows`: Row permutation step
- `MixColumns` / `InvMixColumns`: Column diffusion in `GF(2^8)`
- `KeyExpansion`: Generates the round keys

Internal registers such as `states`, `fullkeys`, `afterSubBytes`,
`afterShiftRows`, `afterMixColumns`, and `afterRoundKey` hold intermediate round
values.

## Control FSM

The control flow is organized around these states:

| State | Purpose |
| --- | --- |
| `S0` | Initialize and wait for `start` |
| `E1` | Initial `AddRoundKey` and `KeyExpansion` |
| `E2` | Encryption rounds 1-9 |
| `E3` | Final encryption round |
| `D1` | Decryption key expansion |
| `D2` | Decryption rounds 10-2 |
| `D3` | Final decryption round |
| `Fi` | Output result and assert `done` |

<img width="1133" height="629" alt="AES-128 FSM diagram" src="https://github.com/user-attachments/assets/9ea2606b-1831-47ba-9376-09134e4bf377" />

## Simulation Result

The testbench validates the common AES-128 example vector:

| Mode | Input | Key | Output |
| --- | --- | --- | --- |
| Encrypt | `00112233445566778899aabbccddeeff` | `000102030405060708090a0b0c0d0e0f` | `69c4e0d86a7b0430d8cdb78070b4c55a` |
| Decrypt | `69c4e0d86a7b0430d8cdb78070b4c55a` | `000102030405060708090a0b0c0d0e0f` | `00112233445566778899aabbccddeeff` |

<img width="947" height="344" alt="AES-128 simulation waveform" src="https://github.com/user-attachments/assets/188f2635-6ff9-4076-b8d2-a3e68eb4a9d9" />

## Source Notes

`AES_128` is the top-level module. It manages the encryption/decryption datapath,
round transitions, key expansion, and final output timing. Arithmetic helpers
implement polynomial multiplication in `GF(2^8)`, including functions such as
`mb2`, `mb3`, and `mb0e`.

## Synthesis Summary

| Metric | Result |
| --- | --- |
| Total on-chip power | 59.886 W |
| Dynamic power | 58.856 W |
| Device static power | 1.029 W |
| Junction temperature | 125.0 C |
| Thermal margin | -52.8 C |

Timing report excerpt:

| Path | From | To | Total Delay (ns) | Logic Delay (ns) | Net Delay (ns) |
| --- | --- | --- | --- | --- | --- |
| Path 1 | `round_reg[1]/G` | `states_reg[0][19]/D` | 5.228 | 1.099 | 4.129 |
| Path 2 | `round_reg[1]/G` | `states_reg[10][19]/D` | 5.228 | 1.099 | 4.129 |
| Path 3 | `round_reg[1]/G` | `states_reg[11][19]/D` | 5.228 | 1.099 | 4.129 |
