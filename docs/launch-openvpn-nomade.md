# Tester Alice
openvpn --config /root/vpn-nomade.ovpn --auth-user-pass /root/alice.txt --daemon ovpn-alice --log /root/alice.log

# Pour couper et passer à un autre utilisateur :
killall openvpn

# Tester Charlie (qui doit se faire rejeter)
openvpn --config /root/vpn-nomade.ovpn --auth-user-pass /root/charlie.txt