## Datasheet

### Overview
The `uart()` IP is a fully parameterised soft IP recording the SoC architecture and ASIC backend informations. The IP features an APB4 slave interface, fully compliant with the AMBA APB Protocol Specification v2.0.

### Feature
* Single wire half duplex mode
* Compatibility with NS16550
* Programmable prescaler
    * max division factor is up to 2^16
    * can be changed ongoing
* Programmable baud-rate generator
    * max transition rate is 2Mbps
* Fully programmable serial configuration
    * 5, 6, 7 or 8 bits data word length
    * 0 or 1 stop bits
    * odd, even, one or zero parity
* Independent send and receive fifo
    * 16~64 data depth
    * empty or no-emtpy status flag
* Three maskable interrupt
    * receive interrupt with programmable threshold
    * send empty interrupt
    * receive data parity err interrupt
* Static synchronous design
* Full synthesizable

### Interface
| port name | type        | description          |
|:--------- |:------------|:---------------------|
| apb4      | interface   | apb4 slave interface |
| uart ->    | interface   | uart slave interface |
| `uart.uart_rx_i` | input | uart rx input |
| `uart.uart_tx_o` | output | uart tx input |
| `uart.irq_o` | output | interrupt output|

### Register

| name | offset  | length | description |
|:----:|:-------:|:-----: | :---------: |
| [LCR](#line-control-register) | 0x0 | 4 | line control register |
| [DIV](#divide-reigster) | 0x4 | 4 | divide register |
| [TRX](#send-receive-reigster) | 0x8 | 4 | send receive register |
| [FCR](#fifo-control-reigster) | 0x10 | 4 | fifo control register |
| [LSR](#line-state-reigster) | 0x14 | 4 | line state register |

#### Line Control Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:9]` | none | reserved |
| `[8:7]` | RW | PS |
| `[6:6]` | RW | PEN |
| `[5:5]` | RW | STB |
| `[4:3]` | RW | WLS |
| `[2:2]` | RW | PEIE |
| `[1:1]` | RW | TXIE |
| `[0:0]` | RW | RXIE |

reset value: `0x0000_0000`

* PS: parity mode
    * `PS = 2'b00`: odd parity
    * `PS = 2'b01`: even parity
    * `PS = 2'b10`: zero parity
    * `PS = 2'b11`: one parity

* PEN: parity bit enable
    * `PEN = 1'b0`: parity bit enable
    * `PEN = 1'b1`: parity bit disable

* STB: stop bit length
    * `STB = 1'b0`: 1 stop bit
    * `STB = 1'b1`: 2 stop bits

* WLS: world length
    * `WLS = 2'b00`: 5-bit data word length
    * `WLS = 2'b01`: 6-bit data word length
    * `WLS = 2'b10`: 7-bit data word length
    * `WLS = 2'b11`: 8-bit data word length

* PEIE: parity error interrupt enable
    * `PEIE = 1'b0`: parity error interrupt enable
    * `PEIE = 1'b1`: parity error interrupt disable

* TXIE: send interrupt enable
    * `TXIE = 1'b0`: send interrupt enable
    * `TXIE = 1'b1`: send interrupt disable

* RXIE: receive interrupt enable
    * `RXIE = 1'b0`: receive interrupt enable
    * `RXIE = 1'b1`: receive interrupt disable

#### Divide Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:16]` | none | reserved |
| `[15:0]` | RW | DIV |

reset value: `0x0000_0002`

* DIV: clock divide value

#### Send Receive Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:8]` | none | reserved |
| `[7:0]` | RW | TRX |

reset value: `0x0000_0000`

* TRX: send and receive shadow value

#### FIFO Control Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:4]` | none | reserved |
| `[3:2]` | WO | RX_TRG_LEVL |
| `[1:1]` | WO | TF_CLR |
| `[0:0]` | WO | RF_CLR |

reset value: `0x0000_0000`

* RX_TRG_LEVL: receive trigger threshold
    * `RX_TRG_LEVL = 2'b00`: 1 receive fifo element threshold
    * `RX_TRG_LEVL = 2'b01`: 2 receive fifo element threshold
    * `RX_TRG_LEVL = 2'b10`: 8 receive fifo element threshold
    * `RX_TRG_LEVL = 2'b11`: 14 receive fifo element threshold

* TF_CLR: send fifo clear
    * `TF_CLR = 1'b0`: send fifo writable
    * `TF_CLR = 1'b1`: send fifo clear

* RF_CLR: receive fifo clear
    * `RF_CLR = 1'b0`: receive fifo readable
    * `RF_CLR = 1'b1`: receive fifo clear

#### Line State Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:7]` | none | reserved |
| `[6:6]` | RO | TEMT |
| `[5:5]` | RO | THRE |
| `[4:4]` | RO | PE |
| `[3:3]` | RO | DR |
| `[2:2]` | RO | PEIP |
| `[1:1]` | RO | TXIP |
| `[0:0]` | RO | RXIP |

reset value: `0x0000_0060`

* TEMT: xxx
* THRE: send fifo empty
* PE: parity error
* DR: data read end
* PEIP: parity error interrupt flag
* TXIP: send interrupt flag
* RXIP: receive interrupt flag

### Program Guide
The software operation of `uart` is simple. These registers can be accessed by 4-byte aligned read and write. C-like pseudocode read operation:
```c
uint32_t val;
val = uart.SYS // read the sys register
val = uart.IDL // read the idl register
val = uart.IDH // read the idh register

```
write operation:
```c
uint32_t val = value_to_be_written;
uart.SYS = val // write the sys register
uart.IDL = val // write the idl register
uart.IDH = val // write the idh register

```

### Resoureces
### References
### Revision History