# UART

## Features
* Single wire half duplex mode
* Programmable prescaler
    * max division factor is up to 2^16
    * can be changed ongoing
* Programmable baud-rate generator
    * max transition rate is 2Mbps
* Fully programmable serial configuration
    * 5, 6, 7 or 8 bits data word length
    * 0 or 1 stop bits
* Independent send and receive fifo
    * 16~64 data depth
    * empty or no-emtpy status flag
* Three maskable interrupt
    * receive interrupt with programmable threshold
    * send empty interrupt
    * receive data parity err interrupt
* Static synchronous design
* Full synthesizable

## Build and Test
```bash
make comp    # compile code with vcs
make run     # compile and run test with vcs
make wave    # open fsdb format waveform with verdi
```