#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <signal.h>
#include <unistd.h>

#include "sx1276.h"


#define LORA_DEFAULT_FREQUENCY      (868000000UL)   // 868MHz
#define LORA_DEFAULT_POWER          20              // 20dBm
#define LORA_DEFAULT_TIMEOUT        500             // 500ms
#define LORA_DEFAULT_SYMB_TIMEOUT   10              // 10Symbols, NOTE: this value will work with Rx
#define LORA_DEFAULT_BANDWIDTH      0               // 125kHz
#define LORA_DEFAULT_DATARATE       6               // 64bits/s
#define LORA_DEFAULT_CODERATE       1               // 4/5
#define LORA_DEFAULT_BANDWIDTH_AFC  0               // LoRa: N/A ( set to 0 )
#define LORA_DEFAULT_PREAMBLE_LEN   8               // 8Bytes
#define LORA_DEFAULT_FIX_LEN        true            // packets length is fixed
#define LORA_DEFAULT_PAYLOAD_LEN    16              // 16Bytes
#define LORA_DEFAULT_CRC_ON         true            // enable crc
#define LORA_DEFAULT_FREQ_HOP_ON    false           // disable frequency hop
#define LORA_DEFAULT_HOP_PERIOD     0               // 0Symbol
#define LORA_DEFAULT_IQ_INVERTED    false           // disable iq inverted
#define LORA_DEFAULT_RX_CONTINUOUS  true            // enable rx continuous

#define LORA_DISABLE_RECEIVE_MODE   0               // disbale receive mode
#define LORA_ENABLE_RECEIVE_MODE    1               // enable receive mode

static int running = 0;

static void signal_handler(int signal)
{
    sx1276_close();
    running = 0;
}

static void lora_usage(void)
{
    fprintf(stdout, "Usage: LoRa test OPTIONS\n");
    fprintf(stdout, "\t-f VAL\tfrequency in kHz\n");
    fprintf(stdout, "\t-p VAL\tpower in dBm\n");
    fprintf(stdout, "\t-t VAL\ttx interval in ms\n");
    fprintf(stdout, "\t-b VAL\tbandwidth\n");
    fprintf(stdout, "\t\t 0: 125 kHz\n");
    fprintf(stdout, "\t\t 1: 250 kHz\n");
    fprintf(stdout, "\t\t 2: 500 kHz\n");
    fprintf(stdout, "\t-d VAL\tdatarate\n");
    fprintf(stdout, "\t\t 6:  64   bits/s\n");
    fprintf(stdout, "\t\t 7:  128  bits/s\n");
    fprintf(stdout, "\t\t 8:  256  bits/s\n");
    fprintf(stdout, "\t\t 9:  512  bits/s\n");
    fprintf(stdout, "\t\t 10: 1024 bits/s\n");
    fprintf(stdout, "\t\t 11: 2048 bits/s\n");
    fprintf(stdout, "\t\t 12: 4096 bits/s\n");
    fprintf(stdout, "\t-c VAL\tcoding rate\n");
    fprintf(stdout, "\t\t 1: 4/5\n");
    fprintf(stdout, "\t\t 2: 4/6\n");
    fprintf(stdout, "\t\t 3: 4/7\n");
    fprintf(stdout, "\t\t 4: 4/8\n");
    fprintf(stdout, "\t-r VAL\treceive mode\n");
}

static void lora_clean_event(void)
{
    int ret = 0;
    event_data_t event;

    do{
        memset(&event, 0, sizeof(event_data_t));
        ret = sx1276_wait_event(&event, 100);
    }while(ret > 0);
}

static void lora_dump_data(char *app, event_data_t *event, uint32_t frequency)
{
    int i;

    if(event->flags == RADIO_EVENT_RX_DONE){
        // PPM: for 868MHz, 1PPM means the frequency need around in
        // ==> (868MHz - 868MHz/1.0e6 * 1, 868MHz + 868MHz/1.0e6 *1)
        // ==> (867999132Hz, 868000868Hz)
        int64_t fe = sx1276_get_frequency_error();
        int64_t ppm = fe * 1000000 / frequency;
        fprintf(stdout, "\n%s Rx done >>\n", app);
        fprintf(stdout, "Rx: KTIME [%u], ATIME [%u]\n", event->ktime, event->atime);
        fprintf(stdout, "Rx: RSSI [%d], SNR [%d], PPM [%d]\n", event->rssi, event->snr, (int32_t)ppm);
        fprintf(stdout, "RX: LENGTH[%d], DATA ==>\n", event->size);
        for(i = 0; i < event->size; ++i){
            if(i && i % 4 == 0)
                fprintf(stdout, " ");
            if(i && i % 16 == 0)
                fprintf(stdout, "\n");
            fprintf(stdout, "[0x%02X]", event->buf[i]);
        }
        fprintf(stdout, "\n\n");
    }else if(event->flags == RADIO_EVENT_RX_TIMEOUT){
        // fprintf(stderr, "%s: Rx event timeout, EVENT [0x%X], KTIME [%u]\n", app, event->flags, event->ktime);
    }else if(event->flags == RADIO_EVENT_RX_ERROR){
        fprintf(stderr, "%s: Rx event error, EVENT [0x%X], KTIME [%u]\n", app, event->flags, event->ktime);
    }
}

int main(int argc, char *argv[])
{
    event_data_t event;
    uint8_t  buf[]     = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};
    uint8_t  size      = sizeof(buf) > LORA_DEFAULT_PAYLOAD_LEN ? sizeof(buf) : LORA_DEFAULT_PAYLOAD_LEN;
    uint32_t bandwidth = LORA_DEFAULT_BANDWIDTH;
    uint32_t datarate  = LORA_DEFAULT_DATARATE;
    uint8_t  coderate  = LORA_DEFAULT_CODERATE;
    uint32_t timeout   = LORA_DEFAULT_TIMEOUT;
    uint32_t frequency = LORA_DEFAULT_FREQUENCY;
    int8_t   power     = LORA_DEFAULT_POWER;
    int8_t   receive   = LORA_DISABLE_RECEIVE_MODE; 
    int      ret;

    while((ret = getopt(argc, argv, "b:d:c:t:f:p:rh")) != -1){
        switch(ret){
            case 'b':
                bandwidth = strtoul(optarg, NULL, 0);
                break;
            case 'd':
                datarate = strtoul(optarg, NULL, 0);
                break;
            case 'c':
                coderate = strtoul(optarg, NULL, 0);
                break;
            case 't':
                timeout = strtoul(optarg, NULL, 0);
                break;
            case 'f':
                frequency = strtoul(optarg, NULL, 0);
                break;
            case 'p':
                power = strtoul(optarg, NULL, 0);
                break;
            case 'r':
                receive = LORA_ENABLE_RECEIVE_MODE;
                break;
            case 'h':
            default:
                lora_usage();
                return 0;
        }
    }

    sx1276_open();
    sx1276_set_modem(MODEM_LORA);
    sx1276_set_channel(frequency);
    sx1276_set_public_network(false);
    lora_clean_event();

    if(receive){
        fprintf(stdout, "\n%s: start Rx process FREQUENCY [%u] >>\n", argv[0], frequency);
        fprintf(stdout, "Rx: BANDWIDTH [%d], DATARATE [%d], CODERATE [%d], PAYLOAD [%d]\n\n", bandwidth, datarate, coderate, size);
        sx1276_set_rx_config(MODEM_LORA, bandwidth, datarate, coderate,
                LORA_DEFAULT_BANDWIDTH_AFC, LORA_DEFAULT_PREAMBLE_LEN, LORA_DEFAULT_SYMB_TIMEOUT,
                LORA_DEFAULT_FIX_LEN, size, LORA_DEFAULT_CRC_ON, LORA_DEFAULT_FREQ_HOP_ON,
                LORA_DEFAULT_HOP_PERIOD, LORA_DEFAULT_IQ_INVERTED, LORA_DEFAULT_RX_CONTINUOUS);
        sx1276_set_rx(0);
    }else{
        fprintf(stdout, "\n%s: start Tx process FREQUENCY [%u] >>\n", argv[0], frequency);
        fprintf(stdout, "Tx: BANDWIDTH [%d], DATARATE [%d], CODERATE [%d], POWER [%d]\n\n", bandwidth, datarate, coderate, power);
        sx1276_set_tx_config(MODEM_LORA, power, 0, bandwidth, datarate, coderate, LORA_DEFAULT_PREAMBLE_LEN,
                LORA_DEFAULT_FIX_LEN, LORA_DEFAULT_CRC_ON, LORA_DEFAULT_FREQ_HOP_ON,
                LORA_DEFAULT_HOP_PERIOD, LORA_DEFAULT_IQ_INVERTED, timeout);
    }

    running = 1;
    signal(SIGINT, signal_handler);

    while(running){
        if(receive){
            memset(&event, 0, sizeof(event_data_t));

            if(sx1276_wait_event(&event, timeout) > 0){
                lora_dump_data(argv[0], &event, frequency);
            }else{
                fprintf(stderr, "%s: No data found from Rx\n", argv[0]);
            }
            sx1276_set_rx(0);
        }else{
            sx1276_send(buf, sizeof(buf));

            memset(&event, 0, sizeof(event_data_t));

            if(sx1276_wait_event(&event, timeout) > 0){
                fprintf(stdout, "%s: Event [%d], Ktime [%u]\n", argv[0], event.flags, event.ktime);
                usleep(timeout * 1000);
            }else{
                fprintf(stderr, "%s: Tx timeout or error\n", argv[0]);
            }
        }
    }

    return 0;
}
