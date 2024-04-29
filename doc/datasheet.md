## Datasheet

### Overview
The `uart(universal asynchronous receiver transmitter)` IP is a fully parameterised soft IP to implement one of the most common asynchronous protocols. The IP features an APB4 slave interface, fully compliant with the AMBA APB Protocol Specification v2.0.

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
* Independent transmit and receive fifo
    * 16~64 data depth
    * empty or no-emtpy status flag
* Three maskable interrupt
    * receive interrupt with programmable threshold
    * transmit empty interrupt
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
| [TRX](#transmit-receive-reigster) | 0x8 | 4 | transmit receive register |
| [FCR](#fifo-control-reigster) | 0x0C | 4 | fifo control register |
| [LSR](#line-state-reigster) | 0x10 | 4 | line state register |

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

* TXIE: transmit interrupt enable
    * `TXIE = 1'b0`: transmit interrupt enable
    * `TXIE = 1'b1`: transmit interrupt disable

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

#### Transmit Receive Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:8]` | none | reserved |
| `[7:0]` | RW | TRX |

reset value: `0x0000_0000`

* TRX: transmit and receive shadow register

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
    * `RX_TRG_LEVL = 2'b01`: 2 receive fifo elements threshold
    * `RX_TRG_LEVL = 2'b10`: 8 receive fifo elements threshold
    * `RX_TRG_LEVL = 2'b11`: 14 receive fifo elements threshold

* TF_CLR: transmit fifo clear
    * `TF_CLR = 1'b0`: transmit fifo writable
    * `TF_CLR = 1'b1`: transmit fifo clear

* RF_CLR: receive fifo clear
    * `RF_CLR = 1'b0`: receive fifo readable
    * `RF_CLR = 1'b1`: receive fifo clear

#### Line State Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:9]` | none | reserved |
| `[8:8]` | RO | FULL |
| `[7:7]` | RO | EMPT |
| `[6:6]` | RO | TEMT |
| `[5:5]` | RO | THRE |
| `[4:4]` | RO | PE |
| `[3:3]` | RO | DR |
| `[2:2]` | RO | PEIP |
| `[1:1]` | RO | TXIP |
| `[0:0]` | RO | RXIP |

reset value: `0x0000_00E0`

* FULL: transmit fifo full
    * `FULL = 1'b0`: transmit fifo is no full
    * `FULL = 1'b1`: otherwise

* EMPT: receive fifo empty
    * `EMPT = 1'b0`: receive fifo is no empty
    * `EMPT = 1'b1`: otherwise

* TEMT: transimtter fifo empty with tx ready 
    * `TEMT = 1'b0`: transmit fifo is no empty
    * `TEMT = 1'b1`: otherwise

* THRE: transimtter holding register empty
    * `THRE = 1'b0`: transmit fifo is no empty
    * `THRE = 1'b1`: otherwise

* PE: parity error
    * `PE = 1'b0`: receive data with parity error
    * `PE = 1'b1`: otherwise

* DR: data ready
    * `DR = 1'b0`: no data in recieve fifo
    * `DR = 1'b1`: otherwise

* PEIP: parity error interrupt flag
    * `PEIP = 1'b0`: trigger parity error interrupt
    * `PEIP = 1'b1`: otherwise

* TXIP: transmit interrupt flag
    * `TXIP = 1'b0`: trigger transmit interrupt
    * `TXIP = 1'b1`: otherwise

* RXIP: receive interrupt flag
    * `RXIP = 1'b0`: trigger receive interrupt
    * `RXIP = 1'b1`: otherwise

### Program Guide
The software operation of `uart` is simple. These registers can be accessed by 4-byte aligned read and write. C-like pseudocode init operation:

```c
uart.LCR = 0
uart.DIV = BAUD_DIV_16_bit     // set baud -> BAUD_DIV_16_bit = 100 x 10^6 / BAUD_VAL - 1
uart.FCR.[TF_CLR, RF_CLR] = 1; // clear tx/rx fifo
uart.FCR.[TF_CLR, RF_CLR] = 0; // restore tx/rx fifo
uart.FCR.RX_TRG_LEVL = 3;      // set receive fifo irq trigger threshold to 14 elements
uart.LCR = 0x1F                // set 8-N-1 format, enable all types irq
```

write operation:
```c
while(uart.LSR.FULL == 1); // wait a while until the tx fifo is no full
uart.TRX = SEND_DATA_8_bit
```

read operation:
```c
uint32_t recv_val;
while(uart.LSR.DR == 1) {  // if rx fifo is no empty
    recv_val = uart.TRX
};

```

### Resoureces
### References
### Revision History