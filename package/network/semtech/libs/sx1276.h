/*
 *  sx1276.h - Semtech SX1276 LoRa Radio network device
 *
 *  Copyright (c) 2018 SaintEgerLeo <saintleo@ioes.cn>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef __SX1276_H__
#define __SX1276_H__

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RX_TX_BUFFER_SIZE                           256

#define RADIO_EVENT_RX_ERROR                        (1 << 1)
#define RADIO_EVENT_RX_DONE                         (1 << 2)
#define RADIO_EVENT_RX_TIMEOUT                      (1 << 3)
#define RADIO_EVENT_TX_DONE                         (1 << 4)
#define RADIO_EVENT_TX_TIMEOUT                      (1 << 5)
#define RADIO_EVENT_CAD_DONE                        (1 << 6)
#define RADIO_EVENT_FHSS_CHANGE_CHANNEL             (1 << 7)

/*!
 * Sync word for Private LoRa networks
 */
#define LORA_MAC_PRIVATE_SYNCWORD                   0x12

/*!
 * Sync word for Public LoRa networks
 */
#define LORA_MAC_PUBLIC_SYNCWORD                    0x34

/*!
 * Radio driver supported modems
 */
typedef enum {
    MODEM_FSK = 0,
    MODEM_LORA,
} radio_modems_t;

/*!
 * Radio driver internal state machine states definition
 */
typedef enum {
    RF_IDLE = 0,   //!< The radio is idle
    RF_RX_RUNNING, //!< The radio is in reception state
    RF_TX_RUNNING, //!< The radio is in transmission state
    RF_CAD,        //!< The radio is doing channel activity detection
} radio_states_t;

typedef struct {
    uint32_t            flags;
    uint32_t            ktime;  // event happened time in kernel [ms]
    uint32_t            atime;  // time on air [ms]
    uint32_t            size;
    int16_t             rssi;
    int8_t              snr;
    uint8_t             buf[RX_TX_BUFFER_SIZE];
} __attribute__ ((packed)) event_data_t;


/*!
 * ============================================================================
 * Public functions prototypes
 * ============================================================================
 */

/*!
 * \brief Initializes and open the radio
 *
 * retval isSuccess [true: opened, flase: can't open]
 */
bool sx1276_open(void);

/*!
 * \brief Deinitializes and close the radio
 */
void sx1276_close(void);

/*!
 * \brief Initializes the radio
 */
void sx1276_reset(void);

/*!
 * Return current radio status
 *
 * \param status Radio status.[RF_IDLE, RF_RX_RUNNING, RF_TX_RUNNING]
 */
radio_states_t sx1276_get_status(void);

/*!
 * \brief Configures the radio with the given modem
 *
 * \param [IN] modem Modem to be used [0: FSK, 1: LoRa]
 */
void sx1276_set_modem(radio_modems_t modem);

/*!
 * \brief Sets the channel configuration
 *
 * \param [IN] freq         Channel RF frequency
 */
void sx1276_set_channel(uint32_t freq);

/*!
 * \brief Checks if the channel is free for the given time
 *
 * \param [IN] modem      Radio modem to be used [0: FSK, 1: LoRa]
 * \param [IN] freq       Channel RF frequency
 * \param [IN] rssi_thresh RSSI threshold
 * \param [IN] max_carrier_sense_time Max time while the RSSI is measured (msecs)
 *
 * \retval isFree         [true: Channel is free, false: Channel is not free]
 */
bool sx1276_is_channel_free(radio_modems_t modem, uint32_t freq, int16_t rssi_thresh, uint32_t max_carrier_sense_time);

/*!
 * \brief Generates a 32 bits random value based on the RSSI readings
 *
 * \remark This function sets the radio in LoRa modem mode and disables
 *         all interrupts.
 *         After calling this function either SX1276SetRxConfig or
 *         SX1276SetTxConfig functions must be called.
 *
 * \retval randomValue    32 bits random value
 */
uint32_t sx1276_random(void);

/*!
 * \brief Sets the reception parameters
 *
 * \remark When using LoRa modem only bandwidths 125, 250 and 500 kHz are supported
 *
 * \param [IN] modem         Radio modem to be used [0: FSK, 1: LoRa]
 * \param [IN] bandwidth     Sets the bandwidth
 *                           FSK : >= 2600 and <= 250000 Hz
 *                           LoRa: [0: 125 kHz, 1: 250 kHz,
 *                                  2: 500 kHz, 3: Reserved]
 * \param [IN] datarate      Sets the Datarate
 *                           FSK : 600..300000 bits/s
 *                           LoRa: [6: 64, 7: 128, 8: 256, 9: 512,
 *                                 10: 1024, 11: 2048, 12: 4096  chips]
 * \param [IN] coderate      Sets the coding rate (LoRa only)
 *                           FSK : N/A ( set to 0 )
 *                           LoRa: [1: 4/5, 2: 4/6, 3: 4/7, 4: 4/8]
 * \param [IN] bandwidth_afc Sets the AFC Bandwidth (FSK only)
 *                           FSK : >= 2600 and <= 250000 Hz
 *                           LoRa: N/A ( set to 0 )
 * \param [IN] preamble_len  Sets the Preamble length
 *                           FSK : Number of bytes
 *                           LoRa: Length in symbols (the hardware adds 4 more symbols)
 * \param [IN] symb_timeout  Sets the RxSingle timeout value
 *                           FSK : timeout number of bytes
 *                           LoRa: timeout in symbols
 * \param [IN] fix_len       Fixed length packets [0: variable, 1: fixed]
 * \param [IN] payload_len   Sets payload length when fixed length is used
 * \param [IN] crc_on        Enables/Disables the CRC [0: OFF, 1: ON]
 * \param [IN] freq_hop_on   Enables disables the intra-packet frequency hopping
 *                           FSK : N/A ( set to 0 )
 *                           LoRa: [0: OFF, 1: ON]
 * \param [IN] hop_period    Number of symbols between each hop
 *                           FSK : N/A ( set to 0 )
 *                           LoRa: Number of symbols
 * \param [IN] iq_inverted   Inverts IQ signals (LoRa only)
 *                           FSK : N/A ( set to 0 )
 *                           LoRa: [0: not inverted, 1: inverted]
 * \param [IN] rx_continuous Sets the reception in continuous mode
 *                           [false: single mode, true: continuous mode]
 */
void sx1276_set_rx_config(radio_modems_t modem, uint32_t bandwidth,
                          uint32_t datarate, uint8_t coderate,
                          uint32_t bandwidth_afc, uint16_t preamble_len,
                          uint16_t symb_timeout, bool fix_len,
                          uint8_t payload_len,
                          bool crc_on, bool freq_hop_on, uint8_t hop_period,
                          bool iq_inverted, bool rx_continuous);

/*!
 * \brief Sets the transmission parameters
 *
 * \remark When using LoRa modem only bandwidths 125, 250 and 500 kHz are supported
 *
 * \param [IN] modem        Radio modem to be used [0: FSK, 1: LoRa]
 * \param [IN] power        Sets the output power [dBm]
 * \param [IN] fdev         Sets the frequency deviation (FSK only)
 *                          FSK : [Hz]
 *                          LoRa: 0
 * \param [IN] bandwidth    Sets the bandwidth (LoRa only)
 *                          FSK : 0
 *                          LoRa: [0: 125 kHz, 1: 250 kHz,
 *                                 2: 500 kHz, 3: Reserved]
 * \param [IN] datarate     Sets the Datarate
 *                          FSK : 600..300000 bits/s
 *                          LoRa: [6: 64, 7: 128, 8: 256, 9: 512,
 *                                10: 1024, 11: 2048, 12: 4096  chips]
 * \param [IN] coderate     Sets the coding rate (LoRa only)
 *                          FSK : N/A ( set to 0 )
 *                          LoRa: [1: 4/5, 2: 4/6, 3: 4/7, 4: 4/8]
 * \param [IN] preamble_len Sets the preamble length
 *                          FSK : Number of bytes
 *                          LoRa: Length in symbols (the hardware adds 4 more symbols)
 * \param [IN] fix_len      Fixed length packets [0: variable, 1: fixed]
 * \param [IN] crc_on       Enables disables the CRC [0: OFF, 1: ON]
 * \param [IN] freq_hop_on  Enables disables the intra-packet frequency hopping
 *                          FSK : N/A ( set to 0 )
 *                          LoRa: [0: OFF, 1: ON]
 * \param [IN] hop_period   Number of symbols between each hop
 *                          FSK : N/A ( set to 0 )
 *                          LoRa: Number of symbols
 * \param [IN] iq_inverted  Inverts IQ signals (LoRa only)
 *                          FSK : N/A ( set to 0 )
 *                          LoRa: [0: not inverted, 1: inverted]
 * \param [IN] timeout      Transmission timeout [ms]
 */
void sx1276_set_tx_config(radio_modems_t modem, int8_t power, uint32_t fdev,
                          uint32_t bandwidth, uint32_t datarate,
                          uint8_t coderate, uint16_t preamble_len,
                          bool fix_len, bool crc_on, bool freq_hop_on,
                          uint8_t hop_period, bool iq_inverted, uint32_t timeout);

/*!
 * \brief Computes the packet time on air in ms for the given payload
 *
 * \Remark Can only be called once SetRxConfig or SetTxConfig have been called
 *
 * \param [IN] modem      Radio modem to be used [0: FSK, 1: LoRa]
 * \param [IN] pkt_len    Packet payload length
 *
 * \retval airTime        Computed airTime (ms) for the given packet payload length
 */
uint32_t sx1276_get_time_on_air(radio_modems_t modem, uint8_t pkt_len);

/*!
 * \brief Sends the buffer of size. Prepares the packet to be sent and sets
 *        the radio in transmission
 *
 * \param [IN]: buffer     Buffer pointer
 * \param [IN]: size       Buffer size
 */
void sx1276_send(uint8_t *buffer, uint8_t size);

/*!
 * \brief Sets the radio in sleep mode
 */
void sx1276_set_sleep(void);

/*!
 * \brief Sets the radio in standby mode
 */
void sx1276_set_standby(void);

/*!
 * \brief Sets the radio in reception mode for the given time
 * \param [IN] timeout Reception timeout [ms] [0: continuous, others timeout]
 */
void sx1276_set_rx(uint32_t timeout);

/*!
 * \brief Start a Channel Activity Detection
 */
void sx1276_start_cad(void);

/*!
 * \brief Sets the radio in continuous wave transmission mode
 *
 * \param [IN]: freq       Channel RF frequency
 * \param [IN]: power      Sets the output power [dBm]
 * \param [IN]: time       Transmission mode timeout [ms]
 */
void sx1276_set_tx_continuous_wave(uint32_t freq, int8_t power, uint16_t time);

/*!
 * \brief Reads the current RSSI value
 *
 * \retval rssiValue Current RSSI value in [dBm]
 */
int16_t sx1276_read_rssi(radio_modems_t modem);

/*!
 * \brief Writes the radio register at the specified address
 *
 * \param [IN]: addr Register address
 * \param [IN]: data New register value
 */
void sx1276_write(uint8_t addr, uint8_t data);

/*!
 * \brief Reads the radio register at the specified address
 *
 * \param [IN]: addr Register address
 * \retval data Register value
 */
uint8_t sx1276_read(uint8_t addr);

/*!
 * \brief Writes multiple radio registers starting at address
 *
 * \param [IN] addr   First Radio register address
 * \param [IN] buffer Buffer containing the new register's values
 * \param [IN] size   Number of registers to be written
 */
void sx1276_write_buffer(uint8_t addr, uint8_t *buffer, uint8_t size);

/*!
 * \brief Reads multiple radio registers starting at address
 *
 * \param [IN] addr First Radio register address
 * \param [OUT] buffer Buffer where to copy the registers data
 * \param [IN] size Number of registers to be read
 */
void sx1276_read_buffer(uint8_t addr, uint8_t *buffer, uint8_t size);

/*!
 * \brief Sets the maximum payload length.
 *
 * \param [IN] modem      Radio modem to be used [0: FSK, 1: LoRa]
 * \param [IN] max        Maximum payload length in bytes
 */
void sx1276_set_max_payload_length(radio_modems_t modem, uint8_t max);

/*!
 * \brief Sets the network to public or private. Updates the sync byte.
 *
 * \remark Applies to LoRa modem only
 *
 * \param [IN] enable if true, it enables a public network
 */
void sx1276_set_public_network(bool enable);

/*!
 * \brief Reads the current Frequency Error value
 *
 * \retval FE Current Frequency Error value in [dBm]
 *
 * \NOTE: used with LoRa mode only
 */
int sx1276_get_frequency_error(void);

/*!
 * \brief Wait for one radio event happen.
 *
 * \param [OUT] event   pointer of event struct.
 * \param [IN]  timeout wait for timeout [ms].
 *
 * retval isSuccess     [0: timeout, >0: event comes, <0: operation error]
 */
int sx1276_wait_event(event_data_t *event, int32_t timeout);

#ifdef __cplusplus
}
#endif

#endif /* __SX1276_H__ */
