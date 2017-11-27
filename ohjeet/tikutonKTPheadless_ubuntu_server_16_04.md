# Abitin tikuton koetilan palvelin

Tässä ohjeessa käydään läpi tikuttoman koetilan palvelimen asentaminen etäkäytettävään palvelimeen, jossa ei ole kiinni näyttöä tai näppäimistöä. Etähallinta toteutetaan ssh:n ja VNC:n avulla. Näiden palvelujen rakentamista ja käyttöä ei käsitellä laajemmin tässä dokumentaatiossa. Palvelinta oletetaan hallittavan sisäverkosta käsin, joten palomuurin rakentamista ei myöskään käydä läpi.

## Laitteisto

PC kone 2:lla verkkokortilla. Näyttö ja näppäimistö asennusvaiheessa. 

## Käyttöjärjestelmän ja ohjelmistojen asennus

Käyttöjärjestelmäksi asennetaan 16.04 LTS ja asennuvaiheessa asennetaan seuraavat ohjelmistot:
* Standard system utilities
* OpenSSH
* Samba file server

Asennuksen jälkeen päivitä järjestelmä komennoilla:
```shell
sudo apt update
sudo apt upgrade
```
Kometojen suorittamisen jälkeen asennetaan loput puuttuvat paketit:
```shell
sudo apt install vagrant virtualbox-qt xvfb x11vnc
```
Pakettien asentamisen jälkeen aletaan konfiguroida järjestelmää.

## Verkon konfigurointi
Suorita komento `ip addr show` selvittääksesi järjestelmän käytössä olevien verkkokorttien
nimet. Ota korttien numerot ja nimet ylös. Tässä dokumentaatiossa nämä kortit nimetään seuraavasti:
1. `lo` -- local loopback verkkokortti
2. `eth0` -- Etäkäyttöverkon verkkokortti
3. `eth1` -- Abittiverkon verkkokortti

Seuraavaksi avaa verkkokonfiguraatiotiedosto komennolla:
```shell
sudo nano /etc/network/interfaces
```

Aukeava tiedosto näyttää jotakuinkin seuraavalta:
```
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet dhcp
```

Muokkaa verkkokonfiguraatiotiedosto vastaamaan seuraavia asetuksia:
```
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# Control network interface
auto eth0
iface eth0 inet static
address <palvelimen hallintaverkon ip osoite>
netmask <hallintaverkon aliverkon peite>
broadcast <hallintaverkon yleislähetysosoite>
gateway <hallintaverkon reitittimen ip osoite>

up ip route add default via <hallintaverkon reitittimen ip osoite>
down ip route del default via <hallintaverkon reitittimen ip osoite>

#Exam network interface, no ip address given
auto eth1
allow-hotplug eth1
iface eth1 inet manual
pre-up ifconfig $IFACE up
pre-down ifconfig $IFACE down
```

Muokkauksen jälkeen sulje tiedosto painamalla ctrl+x ja tämän jälkeen y tallentaaksesi tiedoston.

Lisätään vielä nimipalvelinasetukset koetilan palvelimelle. Avaa asetustiedosto komennolla:
```shell
sudo nano /etc/resolvconf/reslov.conf.d/base
```
Tämä avaa tyhjän tiedoston. Lisätään tiedostoon rivit:
```
nameserver 8.8.8.8
nameserver 8.8.4.4
```

Taas sulje ja tallenna tiedosto painamalla ctrl+x ja y.

Nyt käynnistä järjestelmä uudestaan komennolla:
```shell
sudo reboot
```

Mikäli verkko on oikein kofiguroitu, ja asensit ssh:n käyttöjärjestelmän yhteydessä voit ottaa etähyteyden ssh:n avulla käyttäen koepalvelimen hallintaverkon ip-osoitetta.

## Tikuttoman KTP:n asennus

Asennetaan tikuton ktp ajamalla seuraavat komennot:
```shell
mkdir ~/ktp ~/ktp-jako && cd ~/ktp
wget http://static.abitti.fi/usbimg/qa/vagrant/Vagrantfile
cd ~
```

Lisäksi luodaan käynnistysskripti koepalvelinta varten.
Avataan uusi tiedosto komennolla:
```shell
nano ~/startKTP.sh
```
Kirjoitetaan tiedostolle seuraava sisältö:
```shell
#!/bin/sh

export DISPLAY=:1

cd ~/ktp

vagrant up
```

Sulje ja tallenna tiedosto painamalla ctrl+x ja sen jälkeen y.

Lopuksi annetaan skriptille suoritusoikeudet:
```shell
chmod +x ~/startKTP.sh
```

## VNC-etäkäyttöyhteyden rakentaminen

Tämän jälkeen luodaan käynnistysskripti etähallintaa varten. Luodaan uusi skripti suorittamalla komento:
```shell
nano ~/startXVNCservice.sh
```
Avautuvaan tekstieditoriin kirjoitetaan seuraava sisältö:
```shell
#!/bin/sh

Xvfb :1 -screen 0 1024x786x16 &

x11vnc -sleepin 5 -display :1 -bg -forever -shared -nopw -listen localhost -xkb
```

Ja taas suljetaan ja tallennetaan tiedosto.
Tämä skripti käynnistää virtuaalisen X -serverin, joka vastaa virtuaalista työpöytää tietokoneen muistissa, ja liittää siihen VNC -serverin jonka avulla työpöydän voi avata etänä toiselta koneelta.

Annetaan skriptille suoritusoikeudet ja ajetaan se käynnistääksemme etätyöpöytäpalvelun.
```shell
chmod +x ~/startXVNCservice.sh
~/startXVNCservice.sh
```

Nyt etäkoneelta tunneloi ssh:n avulla tunneloi palvelinkoneen portti 5900 etähallintakoneen porttiin 5900. Linux ja Mac -koneilla tämä voidaan suorittaa ajamalla komentorivikomento:
```shell
ssh -N -T -L 5900:localhost:5900 <käyttäjänimi>@<palvelimen ip osoite>
```
Windows -tietokoneissa tarvitset ssh -etäyhteystyökalun esimerkiksi putty:n. Tunnelin luomista varten tutustu putty:n ohjeisiin.

Nyt voit avata etähallintakoneella VNC -yhteyden osoitteeseen localhost, jonka VNC -porttiin 5900 on tunneloitu palvelimen VNC palvelimen portti. VNC ohjelmistoja ovat esimerkiksi RealVNC, joka on saatavilla kaikille yleisille koneille.

Mikäli kaikki on mennyt oikein tulisi VNC -ohjelmiston avata musta ruutu etäyhteyden merkiksi. VNC -ohjelmisto antaa todennäköisesti varoituksen, että yhteys on salaamaton, mutta tästä varoituksesta ei tarvitse välittää, koska ssh tunneli hoitaa liikenteen salauksen.

VNC -palvelu pysyy päällä niin pitkään, kuin kone on päällä. Uudelleenkäynnistyksen jälkeen VNC -palvelin saadaa pyörimään komennolla:
``` shell
~/startXVNCservice.sh
```
Halutessasi voit suorittaa skriptin käynnistyksen yhteydessä crontab:n tai systemctl:n avulla. Näihin löytyy ohjeita Ubuntun dokumentaatiosta.

## Tikuttoman KTP:n käyttö

Kun VNC -palvelu on päällä palvelimella (etähallintakoneen ei tarvitse muodostaa VNC yhteyttä vielä tässä vaiheessa), suorita palvelimen käynnistysskripti komennolla:
```shell
~/startKTP.sh
```
Palvelin käynnistää itsensä VNC:n läpi saatavalle ruudulle. Ensimmäisellä käynnistyskerralla käynnistyminen vie aikaa n. 20 min, koska palvelin lataa itsensä verkon kautta, mutta seuraavilla kerroilla tämä tapahtuu huomattavasti nopeammin. Käynnistyksen yhteydessä kysytään verkkokorttia, josta valitaan koeverkkoon yhdistetty kortti. Kortti on käynnistetty automaattisesti tietokoneen käynnistymisen yhteydessä, joten siitä ei tarvitse erikseen huolehtia.

## KTP:n koe- ja vastauskansion jakaminen samba -tiedostojakopalvelimen avulla

Tikuton KTP käyttää asennusvaiheessa luotua ktp-jako -kansiota muistitikun tilalla. Etäkäyttöä varten jaetaan tämä kansio samba tiedostonjakopalvelun avulla, joka asennettiin asennuksen yhteydessä. Samba -tiedostonjakopalvelu näkyy kaikilla samassa verkossa olevilla koneilla verkkolevynä, ja on siten erittäin hyvin alustayhteensopiva ratkaisu.

Aloitetaan avaamalla samban konfiguraatiotiedosto komennolla:
```shell
sudo nano /etc/samba/smb.conf
```

Mikäli samba on asennettuna tämä avaa pitkän konfiguraatiotiedoston samba palveluille. Ensimmäisenä muokataan tiedostosta osiota Networking, johon tehdään seuraavat muutokset:
```
intefaces = 127.0.0.0/8 eth0

bind interfaces only = yes
```

Näiden rivien muokkaamisen jälkeen lisää tiedoston loppuun seraavat rivit:
```
[Abitti KTP]
path = /home/<käyttäjänimi>/ktp-jako
valid users = <käyttäjänimi>
read only = no
```

Nyt sulje ja tallenna muokattu tiedosto.

Asetustiedoston muokkaamisen lisäksi tulee käyttäjästä tehdä erikseen samba -käyttäjä. Tämä tapahtuu komennolla:
```shell
smbpasswd -a <käyttäjänimi>
```

Lopuksi käynnistetään samba -tiedostojakopalvelu uudestaan komennolla:
```shell
sudo service smb restart
```

Nyt etähallintakoneen pitäisi nähdä palvelinkoneen jaettu kansio, joka taas näkyy koetilan palvelimen muistitikkuna usb1.




