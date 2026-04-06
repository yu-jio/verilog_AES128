# Design Report: Project AES-128

**Department:** Computer Science and Engineering
**Student ID:** 2021112229
**Name:** Jio Yu (유지오)

---

## 01. Table of Contents
1. DataPath
2. FSM (Finite State Machine)
3. Waveforms
4. Source Description
5. Synthesis Results

---

## 02. DATAPATH

### Input/Output Signals
#### Inputs
* **clk**: Clock signal
* **nrst**: Reset signal (Asynchronous)
* **encdec**: Selection between Encryption (1) or Decryption (0)
* **start**: Start operation signal
* **key**: 128-bit encryption key
* **textin**: 128-bit input data

#### Outputs
* **done**: Operation completion signal
* **textout**: 128-bit result (Encrypted or Decrypted)

### Key Operations
* **AddRoundKey**: XOR operation between the current state and round keys.
* **SubBytes**: Byte-wise data substitution using the AES S-Box.
* **ShiftRows**: Data rearrangement via row shifting.
* **MixColumns**: Polynomial operations in $GF(2^8)$ on a column basis.
* **KeyExpansion**: Generates keys for each round.
* **Inverse Operations**: `InvShiftRows`, `InvSubBytes`, and `InvMixColumns` are used for decryption.

### Round & State Management
* **Round Count**: AES-128 consists of a total of 10 rounds.
* **round**: Variable representing the current round index.
* **states**: 128-bit register array storing the state of each round.
* **fullkeys**: 128-bit register array storing keys for each round.
* **Intermediate Registers**: `afterSubBytes`, `afterShiftRows`, `afterMixColumns`, and `afterRoundKey` store intermediate results.

---

## 03. FSM (Finite State Machine)

The control flow is managed by state transitions:

* **S0**: Initialization and waiting for the start signal.
* **E1 ~ E3**: Encryption process execution.
    * **E1**: Initial `AddRoundKey` and `KeyExpansion`.
    * **E2**: Rounds 1–9 (`SubBytes`, `ShiftRows`, `MixColumns`, `AddRoundKey`, `KeyExpansion`).
    * **E3**: Round 10 (`SubBytes`, `ShiftRows`, `AddRoundKey`).
* **D1 ~ D3**: Decryption process execution.
    * **D1**: `KeyExpansion`.
    * **D2**: Rounds 10–2 (`InvShiftRows`, `InvSubBytes`, `AddRoundKey`, `InvMixColumns`).
    * **D3**: Round 1 (`InvShiftRows`, `InvSubBytes`, `AddRoundKey`).
* **Fi**: Output result and termination (`DONE`).

---

## 04. WAVEFORMS

The simulation demonstrates successful encryption and decryption cycles:

* **Encryption (Encode)**:
    * Input: `00112233445566778899aabbccddeeff`
    * Key: `000102030405060708090a0b0c0d0e0f`
    * Result: `69c4e0d86a7b0430d8cdb78070b4c55a`
* **Decryption (Decode)**:
    * Input: `69c4e0d86a7b0430d8cdb78070b4c55a`
    * Key: `000102030405060708090a0b0c0d0e0f`
    * Result: `00112233445566778899aabbccddeeff` (Original text restored)

---

## 05. SOURCE DESCRIPTION

### Main Module: AES_128
The top-level module manages data flow and state transitions (S0, E1-E3, D1-D3, Fi).

### Operation Functions
* **Substitution**: `SubBytes`, `InvSubBytes` (S-Box/Inverse S-Box).
* **Permutation**: `ShiftRows`, `InvShiftRows`.
* **Diffusion**: `MixColumns`, `InvMixColumns`.
* **Key Management**: `KeyExpansion`, `AddRoundKey`.
* **Arithmetic**: Polynomial multiplication in $GF(2^8)$ (e.g., `mb2`, `mb3`, `mb0e`).

---

## 06. SYNTHESIS RESULTS

### Power Analysis (Synthesized Netlist)
* **Total On-Chip Power**: 59.886 W
* **Dynamic Power**: 58.856 W (98%)
    * **Signals**: 32.390 W (55%)
    * **Logic**: 24.560 W (42%)
    * **I/O**: 1.906 W (3%)
* **Device Static Power**: 1.029 W (2%)
* **Junction Temperature**: 125.0°C (Warning: Junction temperature exceeded!)
* **Thermal Margin**: -52.8°C

### Timing Report Summary
| Path | From | To | Total Delay (ns) | Logic Delay (ns) | Net Delay (ns) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Path 1 | round_reg[1]/G | states_reg[0][19]/D | 5.228 | 1.099 | 4.129 |
| Path 2 | round_reg[1]/G | states_reg[10][19]/D | 5.228 | 1.099 | 4.129 |
| Path 3 | round_reg[1]/G | states_reg[11][19]/D | 5.228 | 1.099 | 4.129 |
