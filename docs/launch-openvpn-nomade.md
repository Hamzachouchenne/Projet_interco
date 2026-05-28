# Tester Alice
openvpn --config vpn-nomade.ovpn --auth-user-pass alice.txt --daemon ovpn-alice --log alice.log

# Pour couper et passer à un autre utilisateur :
killall openvpn

# Tester Charlie (qui doit se faire rejeter)
openvpn --config vpn-nomade.ovpn --auth-user-pass charlie.txt --daemon ovpn-charlie --log charlie.log