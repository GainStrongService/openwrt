uci set network.3g='interface'
uci set network.3g.proto='3g'
uci set network.3g.service='umts'
uci set network.3g.username='root'
uci set network.3g.password='123456'
uci set network.3g.device='/dev/ttyUSB0'
uci set network.3g.apn='internet'
uci commit
