# Verilog Implementation of a Fully Pipelined Matrix Multiplier

## Lab Manual

**School of Integrated Circuit Science and Engineering, Beihang University**
**Instructor: Wang Kang  |  Teaching Assistants: Kou Jing, Zhang Liang, Jiang He**
**March 30, 2026**

---

## Course Background and Learning Path

Digital processors perform data computation through arithmetic circuits, while AI chips go further by organizing large numbers of arithmetic units to efficiently execute the matrix multiplications and tensor operations found in neural networks. Whether it is the arithmetic logic unit (ALU) in a general-purpose processor or the multiply-accumulate (MAC) datapath in a digital signal processor, none can function without addition, multiplication, and their combinations. Understanding these modules is a prerequisite for understanding why chips can compute at high speed, and why trade-offs among performance, area, and power are necessary.

The linear projections, feed-forward networks, and attention matrix computations in large language models provide a direct context for learning matrix-operation hardware. Public material from Google lists the matrix multiply unit and the systolic array as key components of the TPU, demonstrating the practical industrial value of such structures. [1]

This course follows the path **"adder → multiplier → matrix-computation array"**: the first lab addresses the carry-propagation problem in binary addition; the second lab implements integer multiplication using partial-product compression and fast addition; the third lab maps MAC operations onto an array of processing elements with registers, completing matrix computation through pipelining and data reuse. The three labs correspond respectively to three levels — bit-level operations, arithmetic modules, and array architecture — and form an important foundation for getting started with digital processors, DSPs, and AI computing chips.

This learning path trains not only Verilog description and simulation-based verification skills, but also algorithm-to-hardware design thinking: the same mathematical expression can correspond to different circuit structures; whether a circuit computes correctly, whether it can run at the target clock frequency, and whether it can process data continuously are interrelated questions that must nevertheless be verified separately.

---

## Lab 1: Parallel-Prefix Carry Adder

### 1. Background

An adder performs the summation of binary numbers and is a fundamental circuit in the arithmetic operations, address computation, and accumulation paths of MAC units in digital processors. In AI computing, a dot product requires adding multiple products together, so the speed and hardware cost of the adder also affect the entire MAC datapath.

The most straightforward implementation is the ripple-carry adder: multiple full adders are cascaded, with each stage passing its carry to the next higher bit. This structure is simple to connect, but in the worst case the high-order result must wait for the carry to propagate bit by bit from the least significant bit, and the carry path grows longer as the bit width increases. For processors and computing units that need to operate at high frequencies, this serial dependency can become the critical path.

To shorten the waiting time of carry computation, one can first describe the conditions under which each bit generates and propagates a carry, and then use an associative interval-merge operation to reorganize the bit-by-bit recurrence into a tree-structured prefix network. The recursive-doubling study published by Peter M. Kogge and Harold S. Stone in 1973 is an important theoretical source of the Kogge–Stone structure. [2]

Parallel-prefix adders reduce the logic depth of carry computation from linear growth with bit width to logarithmic growth. The cost is additional logic nodes and wiring, so different structures require trade-offs among speed, area, fanout, and routing. The work of Brent and Kung further emphasizes regular layout and area considerations. [3]

Through the design of a 19-bit adder, this lab teaches how to convert serial data dependencies into a parallel circuit, and provides a reusable module for the final summation of the multiplier in later labs. Actual performance must still be judged in combination with synthesis and timing results; fewer theoretical levels do not guarantee higher speed on every process or FPGA.

### 2. Principles

#### (1) Why does an adder need carry optimization?

Let the two 19-bit inputs be $A$ and $B$, and the input carry be $cin$. The adder computes:

$$\{cout,\ sum[18:0]\} = A + B + cin$$

The least significant bit is numbered 0, and let $c_0 = cin$. For bit $i$, define the carry-generate signal and the carry-propagate signal:

$$g_i = a_i \land b_i, \qquad p_i = a_i \oplus b_i$$

Then:

$$c_{i+1} = g_i \lor (p_i \land c_i), \qquad s_i = p_i \oplus c_i$$

$g_i = 1$ means the bit directly generates a carry; $p_i = 1$ means the bit propagates the incoming carry to the higher bit. A ripple-carry adder computes $c_i$ bit by bit, and the high-order result may have to wait for the low-order carries to propagate in sequence. As the bit width increases, this dependency chain becomes the speed bottleneck.

#### (2) Turning bit-by-bit recurrence into tree-structured parallel computation.

For a segment of binary bits from $j$ to $i$, define the group generate signal $G_{i:j}$ and the group propagate signal $P_{i:j}$ such that:

$$c_{i+1} = G_{i:j} \lor (P_{i:j} \land c_j)$$

Adjacent higher and lower intervals can be merged:

$$(G_H, P_H) \circ (G_L, P_L) = \big(G_H \lor (P_H \land G_L),\ P_H \land P_L\big)$$

This operation is associative, so a tree-structured network can compute multiple prefix intervals simultaneously. Once every $G_{i:0}$ and $P_{i:0}$ is obtained, the carry of each bit can be derived in combination with $cin$, and finally $sum$ and $cout$ are generated. Here, "parallel" refers to parallel computation in circuit space.

Taking the Kogge–Stone network with doubling distances as an example, the merge distances for a 19-bit input are 1, 2, 4, 8, and 16 — a total of 5 prefix-merge levels. For low-order nodes that do not satisfy the merge condition, the result from the previous level is passed through directly. The number of prefix-merge levels is not equal to the gate-level delay of the complete circuit; input preprocessing, the final summation, and wiring also affect the actual timing.

#### (3) Different prefix structures embody different design trade-offs.

Sklansky, Kogge–Stone, Brent–Kung, and Han–Carlson all organize their networks around the same carry-merge operation, but differ in node count, logic depth, fanout, and wiring. The value of prefix design lies in shortening the carry dependency path, while hardware cost must also be considered. The classic work of Brent and Kung particularly emphasizes regular layout and area. [3]

This lab requires combinational logic, so no clocked registers may be added inside the module. Combinational logic still has propagation delay; "no clock input" does not mean the result is produced instantaneously. In addition, 19 is not an integer power of 2, so the prefix connections near the most significant bit and the array index boundaries should be checked with particular care.

### 3. Lab Content and Requirements

Implement the following module in Verilog, and complete the design in combination with the lectures.

#### Module Interface

Module name: `ADDER`

| Signal | Direction | Description |
| ------ | --------- | ----------- |
| `in1[18:0]`, `in2[18:0]` | Input | Two 19-bit operands |
| `cin` | Input | Carry-in |
| `sum[18:0]` | Output | 19-bit sum |
| `cout` | Output | Carry-out |

#### Implementation Requirements

1. Complete a 19-bit parallel-prefix carry adder.
2. Sklansky, Kogge–Stone, Brent–Kung, and Han–Carlson structures are all acceptable.
3. Combinational logic must be used; the module has no clock signal input.

---

## Lab 2: Shift-and-Add Multiplier

### 1. Background

A multiplier computes the product of two numbers and is a fundamental arithmetic module in digital filtering, correlation computation, and matrix operations. The dot-product operations of neural networks repeatedly multiply inputs by weights and then accumulate the products, so the integer multiplier is an important starting point for understanding digital signal processors and low-precision AI computing units.

Binary multiplication can be expanded into a sum of multiple shifted partial products. If the partial products are accumulated one by one, or if multiple ordinary carry-propagate adders are cascaded, the computation must go through multiple rounds of summation and carry propagation. The former limits throughput in an iterative implementation; the latter forms a long critical path in a combinational implementation. The core of the problem is: when adding multiple operands, there is no need to immediately compute the complete binary sum at every step.

In 1964, C. S. Wallace proposed a classic fast multiplication method that uses a tree structure to compress and reduce the partial products. A carry-save adder (CSA) compresses three operands into two vectors, keeping the carries within the compression layer instead of performing full-word-length carry propagation; after repeated compression, a fast adder completes the final summation. [4]

This method reduces the serial dependency of summation through parallel compression, so that the partial-product compression depth grows logarithmically. Its advantage is the ability to shorten the multiplier datapath; its costs include the compression cells and interconnect resources. It forms a division of labor with the parallel-prefix adder: the former reduces the number of operands, while the latter accelerates the carry computation of the final two operands.

This lab targets 8-bit unsigned integers, connecting partial-product generation, Wallace-tree compression, and fast addition. The published paper on the first-generation Google TPU describes a matrix-computing core containing 65,536 8-bit MAC units, showing that low-bit-width arithmetic has practical value for AI inference; that material does not, however, demonstrate that its internals adopt the specific multiplier topology assigned in this lab. [5] The UINT8 arithmetic in this lab is the basic form; when extending to quantized models, numerical rules such as sign, scaling factor, and zero point must also be handled.

### 2. Principles

#### (1) Deriving partial products from the binary expansion.

Let $A$ and $B$ be 8-bit unsigned integers, and let $b_j$ be the $j$-th bit of $B$. Then:

$$A \times B = \sum_{j=0}^{7} (A \times b_j) \cdot 2^j$$

Since $b_j$ can only be 0 or 1, each partial product requires only a bitwise AND operation and a fixed shift: when $b_j$ is 0, the row is all zeros; when $b_j$ is 1, the row is the value of $A$ shifted left by $j$ bits. The shift must be performed on a sufficiently wide unsigned signal to avoid premature truncation of intermediate expressions.

This lab generates 8 partial products in parallel and completes the compression through a Wallace tree.

#### (2) Compressing multiple operands with carry-save adders.

If ordinary adders are cascaded directly, every summation requires carry propagation. A carry-save adder (CSA) instead compresses three inputs into two outputs, temporarily retaining the carries. For $x_i$, $y_i$, $z_i$ of the same bit weight:

$$s_i = x_i \oplus y_i \oplus z_i$$

$$q_i = (x_i \land y_i) \lor (x_i \land z_i) \lor (y_i \land z_i)$$

Provided that the most significant carry is retained, the vectors satisfy:

$$X + Y + Z = S + (Q \ll 1)$$

$S$ holds the sum of the current bit position, and $Q$ shifted left by one bit represents the carries to be counted into the next higher bit. Within one CSA layer, individual bits do not need to wait for carries from adjacent lower bits, so they can operate in parallel. A consistent convention must be adopted in the implementation: if the CSA already outputs a left-shifted carry vector, the next stage must not shift it again.

#### (3) Wallace-tree compression, followed by the final addition.

A Wallace tree compresses multiple bits of the same weight layer by layer until only two vectors remain to be added. When the compression tree is organized with vector-level CSAs, the number of operands evolves as follows:

$$8 \rightarrow 6 \rightarrow 4 \rightarrow 3 \rightarrow 2$$

Remaining vectors fewer than three are passed directly to the next layer. The final two terms are added using the 19-bit parallel-prefix adder from Lab 1, with $cin$ tied to 0 and the inputs zero-extended as necessary. The two circuits have a clear division of labor: the CSA tree reduces the number of operands to be added, and the prefix adder completes the final carry propagation.

The maximum result of 8-bit unsigned multiplication is $255 \times 255 = 65025$, which is less than $2^{16}$, so the complete product can be represented in 16 bits. Internally interfacing with a 19-bit adder facilitates module reuse, but the compression and extension processes must still be correct; the correct result should have zeros at bit 16 and above.

### 3. Lab Content and Requirements

Implement the following module in Verilog, and complete the design in combination with the lectures.

#### Module Interface

Module name: `MULT`

| Signal | Direction | Description |
| ------ | --------- | ----------- |
| `in1[7:0]`, `in2[7:0]` | Input | Two 8-bit unsigned integers |
| `res[15:0]` | Output | 16-bit product |

#### Implementation Requirements

1. Complete a shift-and-add multiplier for 8-bit unsigned integers.
2. The addition of the 8 partial products shall use a Wallace-tree structure.
3. The two partial sums after Wallace-tree compression shall be added using the parallel-prefix carry adder designed in Lab 1.

---

## Lab 3: Fully Pipelined Systolic-Array Matrix Multiplier

### 1. Background

Matrix multiplication combines multiple sets of inputs with multiple sets of coefficients and is an important foundation of linear transforms and neural-network computation. The linear projections, feed-forward networks, and attention computations in large language models all involve matrix operations. In hardware, one matrix multiplication can be decomposed into a large number of multiply-accumulate operations, so it is necessary to study how to organize multiple MAC units so that they work together continuously.

If only a few arithmetic units are reused to sequentially complete all the MACs, one matrix takes a long time to finish; if arithmetic units are simply added without data reuse and scheduling, the same inputs and weights may be read repeatedly, and computing units may sit idle while waiting for data. After scaling up the parallelism, data supply, interconnect, and memory access also become efficiency bottlenecks.

H. T. Kung and Charles E. Leiserson proposed and developed the systolic-array concept in the late 1970s, combining regularly connected processing elements with data flowing in rhythm. The first draft of their report *Systolic Arrays (for VLSI)* is dated 1978, with report number CMU-CS-79-103. This structure coordinates computation with local data transfer, providing an organization suitable for VLSI implementation of repetitive numerical computations. [6]

A weight-stationary systolic array keeps the weights inside the processing elements so that multiple batches of inputs reuse the loaded weights; inputs and partial sums are transferred between adjacent units on clock beats, and the pipeline overlaps the computation of different data. Its advantages are regular local connections, weight reuse, and continuous computing capability. The actual benefit depends on input scheduling, array utilization, and weight-swapping overhead; sustained throughput cannot be inferred from the number of MAC units alone.

Google's first-generation TPU adopted a 256 × 256 matrix-computing structure and is a representative example of systolic arrays used for AI computing. [7] This lab presents the same kind of core problems with a 4 × 4 array: how computation is mapped to processing elements, how inputs and partial sums are aligned, and how the pipeline keeps running. For tasks such as attention, where operands vary with the input, the reuse opportunities of resident weights must also be analyzed. Completing this lab will establish a foundation for further study of memory, scheduling, and operator organization in AI chips.

### 2. Principles

#### (1) Matrix multiplication consists of multiple dot products.

Let the weight matrix be $K$, the input matrix be $X$, and the output be $Y$:

$$Y = KX, \qquad y_{ij} = \sum_{k=0}^{3} K_{ik} X_{kj}$$

Each output element corresponds to a sum of 4 products, and the 16 output elements require 64 scalar multiplications in total. Direct mathematical summation requires 48 additions; if the hardware organizes the computation starting from zero partial sums, it can also be described as 64 MAC updates. Performance statistics should clearly state which counting convention is used.

#### (2) Weight-stationary: let inputs and partial sums move on clock beats.

A systolic array consists of regularly connected processing elements (PEs). Each PE holds one weight and performs the operation of multiplying the input by the weight and then adding the incoming partial sum:

$$p_{out} = p_{in} + w \times x$$

"Weight-stationary" means that a weight resides inside a PE for a period of computation and is reused by multiple batches of inputs; inputs and partial sums move beat by beat through registers between adjacent PEs. Here the partial sum is passed in from the previous PE; there is no need for each PE to accumulate locally and repeatedly.

A weight-stationary array can adopt the following mapping: the PE at physical row $k$ and column $i$ holds $K_{ik}$; input $X_{kj}$ moves from left to right along row $k$; partial sums move from top to bottom along column $i$. The top partial sums are initialized to 0, and the bottom outputs $y_{ij}$. The first physical row holds $K_{00}$, $K_{10}$, $K_{20}$, $K_{30}$ in order, so that the weight layout matches the dataflow of inputs and partial sums.

#### (3) The key to correct pipeline operation is data alignment.

The multiplied input and weight must correspond to the same summation term, and the incoming partial sum must also belong to the same output element. For the above mapping, if an input is delayed by one beat for each PE it crosses horizontally, and a partial sum is delayed by one beat for each PE it crosses vertically, then the input of row $k$ can be injected $k$ beats later relative to row 0.

For example, at the agreed input beat $t = j + k$, $X_{kj}$ is fed into the left boundary of row $k$; it reaches column $i$ at beat $j + k + i$. The partial sum from the previous row required by that PE should also arrive at this beat. This example illustrates the reason for the skewed injection of inputs. The actual time of the first output also depends on boundary sampling and the internal register definitions of the PE, and a complete cycle table should be drawn accordingly.

The array outputs may likewise carry inter-column skew. Since the output interface represents 16 elements simultaneously with `res[303:0]`, the outputs must also be collected — delayed and aligned when necessary — and the time at which the entire `res` group is valid must be made clear.

#### (4) Distinguishing pipeline latency from throughput.

A pipeline uses registers to divide a long combinational path into shorter paths, so that multiple sets of data are processed in an overlapped fashion across different stages. Latency describes how many beats a set of data takes from entry to completion; throughput describes how much data can be completed per unit time. "Fully pipelined" does not by itself mean that one complete 4 × 4 matrix is output per beat.

If each of the 16 PEs completes one valid MAC per beat, the ideal peak is 16 MACs/beat. A complete matrix multiplication contains 64 product contributions, so under this hardware assumption, even without counting fill, drain, and loading overhead, at least 4 beats of computing capacity are required on average. Actual throughput is also affected by input scheduling, output collection, and weight-swapping overhead.

#### (5) Clarifying bit widths and loading control.

The two 128-bit inputs can each hold 16 8-bit elements. The maximum value of each output is:

$$y_{ij\_max} = 4 \times 255 \times 255 = 260100 < 2^{18}$$

Therefore, each result in this task can be represented exactly in 18 bits. The output interface `res` is 304 bits wide, allocated at 19 bits per element, reserving one extra bit beyond the 18 bits required by this lab.

When `load = 1`, computation stops and the weights are loaded; when `load = 0`, the array performs pipelined computation. The design must also clarify the reset behavior of `rst_n` and its priority relative to `load`. If the weights are changed while old data has not yet been drained, old partial sums may mix with the new weights, so a convention is needed: load only after draining, or discard the old computation and restart when loading.

### 3. Lab Content and Requirements

Implement the following module in Verilog, and complete the design in combination with the lectures.

#### Module Interface

Module name: `MULT`

| Signal | Direction | Description |
| ------ | --------- | ----------- |
| `input[127:0]` | Input | Input matrix |
| `weight[127:0]` | Input | Weight matrix |
| `clk`, `rst_n`, `load` | Input | Clock, reset, and weight-load control |
| `res[303:0]` | Output | Matrix computation result |

#### Implementation Requirements

1. Complete a systolic-array matrix multiplier that multiplies two 4 × 4 unsigned-integer matrices.
2. Adopt the weight-stationary scheme with flowing inputs and outputs.
3. The matrix multiplier shall adopt a pipelined structure.
4. When `load` is set to 0, the array performs pipeline computation normally; when `load` is set to 1, the array stops computing and loads the weights into the array.

In the interface, `input` denotes the input data bus; since `input` is a Verilog keyword, a legal identifier such as `input_data` should be used in the code. The element ordering of the matrix buses, the reset scheme, the input acceptance beats, and the output-valid timing should be clearly documented in the design.

---

## References

The full list of materials cited in the text, with complete URLs, is given below.

[1] Google TPU Introduction
<https://cloud.google.com/tpu>

[2] Original Paper by Kogge and Stone
<https://gwern.net/doc/cs/algorithm/1973-kogge.pdf>

[3] Original Brent–Kung Paper
<https://www.eecs.harvard.edu/~htk/publication/1982-ton-brent-kung.pdf>

[4] Wallace Paper Record and Original Entry
<https://ieeemilestones.ethw.org/File:A_suggestion_for_a_fast_multiplier.pdf>

[5] Original TPU Paper
<https://arxiv.org/abs/1704.04760>

[6] Original Report by Kung and Leiserson
<https://www.eecs.harvard.edu/htk/static/files/1978-cmu-cs-report-kung-leiserson.pdf>

[7] Google's First-Generation TPU Architecture Description
<https://cloud.google.com/blog/products/ai-machine-learning/an-in-depth-look-at-googles-first-tensor-processing-unit-tpu>