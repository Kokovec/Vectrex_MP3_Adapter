# Vectrex_MP3_Adapter
![IMG_4028 - Copy](https://github.com/user-attachments/assets/20ccb394-113b-4cba-8f7a-0260219995ce)


This is a very basic MP3 player for the Vectrex.

MP3 (or WAV) files can be loaded onto an SD Card and commands can be issued from the Vectrex to Play, Pause, etc.<br />
Although the player can choose a track to play, there's no method to organize files on the SD Card other than the order in which they are copied onto the card.<br />
In other words, the first file you copy onto the SD card will be Track-1, then next one will be Track-2, etc.<br />
A utility such as SD Sorter(https://www.trustfm.net/software/utilities/SDSorter.php) can be used to ensure files on the SD Card are properly ordered.<br />
The adapter provides for stereo output and you can attach an old-school pair of headphones (with volume pot) or, better yet, powered speakers.<br />

The adapter receives commands from the Vectrex via a crude SPI interface (CPOL=0, CPHA=0, MSB First).<br />
The pinouts are:<br />

![Pinout](https://github.com/user-attachments/assets/8f0dcf03-13b5-44d4-bd10-0aafabd79302)

The Playing Flag is a signal that lets the Adapter know if a tune is playing or paused (there's no stop command).<br />
1 = Playing<br />
0 = Paused<br />
Since the MP3 Player takes some time to process a command, the signal can lag by up to 1 second from the Vectrex sending a command to play or pause.

![Signals](https://github.com/user-attachments/assets/7ae88090-a534-4bdd-87a4-c4643296a73d)

The SPI serial data is 16 bits long (2 bytes) where:<br />
First Byte = Command<br />
Second Byte = Data<br />

![Commands](https://github.com/user-attachments/assets/8739a1a2-ec28-463b-8158-85f8eef71325)


The Adpater uses a PI PICO coupled with a cheap but effective MP3 player module (https://diyables.io/products/mp3-player-module).<br />
<br />
<br />

Video of it in action:<br />
https://rumble.com/v6argvv-vectrex-mp3-player.html

