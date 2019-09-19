/*
 * Atheros OOLITE_V5 reference board support
 *
 * Copyright (c) 2013 The Linux Foundation. All rights reserved.
 * Copyright (c) 2012 Gabor Juhos <juhosg@openwrt.org>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include <linux/platform_device.h>
#include <linux/ath9k_platform.h>
#include <linux/ar8216_platform.h>

#include <asm/mach-ath79/ar71xx_regs.h>

#include "common.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-spi.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "machtypes.h"
#include "pci.h"

#define OOLITE_V5_GPIO_BTN_RST                   17
#define OOLITE_V5_GPIO0                         0
#define OOLITE_V5_GPIO1                         1
#define OOLITE_V5_GPIO2                         2
#define OOLITE_V5_GPIO3                         3
#define OOLITE_V5_GPIO4                         4
#define OOLITE_V5_GPIO11                        11
#define OOLITE_V5_GPIO12                        12
#define OOLITE_V5_GPIO13                        13
#define OOLITE_V5_GPIO14                        14
#define OOLITE_V5_GPIO15                        15
#define OOLITE_V5_GPIO16                        16


#define OOLITE_V5_MAC0_OFFSET                   0
#define OOLITE_V5_MAC1_OFFSET                   6
#define OOLITE_V5_WMAC_CALDATA_OFFSET           0x1000
enum GPIO {
	WAN,
	LAN1,
	LAN2,
	LAN3,
	LAN4
};
unsigned char ap147_gpios[2][6] __initdata = {
	{OOLITE_V5_GPIO4, OOLITE_V5_GPIO16, OOLITE_V5_GPIO15,
	OOLITE_V5_GPIO14, OOLITE_V5_GPIO11, OOLITE_V5_GPIO_BTN_RST},
	{0}
}; 

static const char *oolite_v5_part_probes[] = {
        "tp-link",
        NULL,
};

static struct flash_platform_data oolite_v5_flash_data = {
        .part_probes    = oolite_v5_part_probes,
};


static struct gpio_keys_button ooliteV5_gpio_keys[] __initdata = {
{
    .desc   = "reset button",
    .type   = EV_KEY,
    .code   = KEY_RESTART,
    .debounce_interval = 60,
    .gpio   = OOLITE_V5_GPIO_BTN_RST,
    .active_low = 1,
},
    };
static struct gpio_led oolite_v5_leds_gpio[] __initdata = {
        {
                .name       = "oolite_v5:gpio0",
                .gpio       = OOLITE_V5_GPIO0,
                .active_low = 1,
        }, {
                .name       = "oolite_v5:gpio1",
                .gpio       = OOLITE_V5_GPIO1,
                .active_low = 1,
        }, {
                .name       = "oolite_v5:gpio2",
                .gpio       = OOLITE_V5_GPIO2,
                .active_low = 1,
        }, {
                .name       = "oolite_v5:gpio3",
                .gpio       = OOLITE_V5_GPIO3,
                .active_low = 1,
        }, {
                .name       = "oolite_v5:gpio4",
                .gpio       = OOLITE_V5_GPIO4,
                .active_low = 1,
        }, {
                .name       = "oolite_v5:gpio11",
                .gpio       = OOLITE_V5_GPIO11,
                .active_low = 1,
        }, {
                .name       = "oolite_v5:gpio12",
                .gpio       = OOLITE_V5_GPIO12,
                .active_low = 1,
        }, {
                .name       = "oolite_v5:gpio13",
                .gpio       = OOLITE_V5_GPIO13,
                .active_low = 1,
        }, {
                .name       = "oolite_v5:gpio14",
                .gpio       = OOLITE_V5_GPIO14,
                .active_low = 1,
        }, {
                .name       = "oolite_v5:gpio15",
                .gpio       = OOLITE_V5_GPIO15,
                .active_low = 1,
        }, {
                .name       = "oolite_v5:gpio16",
                .gpio       = OOLITE_V5_GPIO16,
                .active_low = 1,
        },
};


/*static void __init oolite_v5_gpio_led_setup(void)
{
        unsigned int old_func, new_func;
        void __iomem *QCA9531_GPIO_FUNC = ioremap_nocache(AR71XX_GPIO_BASE + 0x6c, 0x04);
        // Disable JTAG
        old_func = __raw_readl(QCA9531_GPIO_FUNC);
        new_func = old_func | (1 << 1);
        __raw_writel(new_func, QCA9531_GPIO_FUNC);
        iounmap(QCA9531_GPIO_FUNC);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(oolite_v5_leds_gpio),
			oolite_v5_leds_gpio);
}*/


static void __init ap147_gpio_led_setup(int board_version)
{
	ath79_gpio_direction_select(ap147_gpios[board_version][WAN], true);
	ath79_gpio_direction_select(ap147_gpios[board_version][LAN4], true);
	ath79_gpio_direction_select(ap147_gpios[board_version][LAN3], true);
	ath79_gpio_direction_select(ap147_gpios[board_version][LAN2], true);
	ath79_gpio_direction_select(ap147_gpios[board_version][LAN1], true);
												  
								   

	ath79_gpio_output_select(ap147_gpios[board_version][WAN],
			QCA953X_GPIO_OUT_MUX_LED_LINK5);
	ath79_gpio_output_select(ap147_gpios[board_version][LAN4],
			QCA953X_GPIO_OUT_MUX_LED_LINK1);
	ath79_gpio_output_select(ap147_gpios[board_version][LAN3],
			QCA953X_GPIO_OUT_MUX_LED_LINK2);
	ath79_gpio_output_select(ap147_gpios[board_version][LAN2],
			QCA953X_GPIO_OUT_MUX_LED_LINK3);
	ath79_gpio_output_select(ap147_gpios[board_version][LAN1],
			QCA953X_GPIO_OUT_MUX_LED_LINK4);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(oolite_v5_leds_gpio),
			oolite_v5_leds_gpio);
	ath79_register_gpio_keys_polled(-1, 20,
			ARRAY_SIZE(ooliteV5_gpio_keys),
			ooliteV5_gpio_keys);
}

static void __init oolite_v5_setup(void)
{
	u8 *art = (u8 *) KSEG1ADDR(0x1fff0000);

	ath79_register_m25p80(&oolite_v5_flash_data);

//	oolite_v5_gpio_led_setup();

	ap147_gpio_led_setup(0);
	ath79_register_usb();
        ath79_register_pci();

	ath79_register_wmac(art + OOLITE_V5_WMAC_CALDATA_OFFSET, NULL);


	ath79_setup_ar933x_phy4_switch(false, false);

    ath79_register_mdio(0, 0x0);

    ath79_switch_data.phy4_mii_en = 1;
    ath79_switch_data.phy_poll_mask |= BIT(4);

    /* LAN */
    ath79_eth1_data.duplex = DUPLEX_FULL;
    ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_GMII;
    ath79_init_mac(ath79_eth1_data.mac_addr, art + OOLITE_V5_MAC1_OFFSET, 0);
    ath79_register_eth(1);

    /* WAN */
    ath79_eth0_data.duplex = DUPLEX_FULL;
    ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_MII;
    ath79_eth0_data.phy_mask = BIT(4);
    ath79_eth0_data.speed = SPEED_100;
    ath79_init_mac(ath79_eth0_data.mac_addr, art + OOLITE_V5_MAC0_OFFSET, 0);
    ath79_register_eth(0);
/*	ath79_register_mdio(0, 0x0);
	ath79_register_mdio(1, 0x0);

	ath79_init_mac(ath79_eth0_data.mac_addr, art + OOLITE_V5_MAC0_OFFSET, 0);
	ath79_init_mac(ath79_eth1_data.mac_addr, art + OOLITE_V5_MAC1_OFFSET, 0);
*/
	/* WAN port */
/*	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_MII;
	ath79_eth0_data.speed = SPEED_100;
	ath79_eth0_data.duplex = DUPLEX_FULL;
	ath79_eth0_data.phy_mask = BIT(4);
	ath79_register_eth(0);
*/
	/* LAN ports */
/*	ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_GMII;
	ath79_eth1_data.speed = SPEED_1000;
	ath79_eth1_data.duplex = DUPLEX_FULL;
	ath79_switch_data.phy_poll_mask |= BIT(4);
	ath79_switch_data.phy4_mii_en = 1;
	ath79_register_eth(1);*/
}

MIPS_MACHINE(ATH79_MACH_OOLITE_V5, "OOLITE_V5", "Oolite V5 board",
	     oolite_v5_setup);

