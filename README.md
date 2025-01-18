# Vectrex_MP3_Adapter

![IMG_4028 - Copy](https://github.com/user-attachments/assets/73ef259a-1360-4992-972f-5f8a7e94e581)
This is a very basic MP3 player for the Vectrex.

MP3 (or WAV) files can be loaded onto an SD Card and commands can be issued from the Vectrex to Play, Pause, etc.<br />
Although the player can choose a track to play, there's no method to organize files on the SD Card other than the order in which they are copied onto the card.<br />
In other words, the first file you copy onto the SD card will be Track-1, then next one will be Track-2, etc.<br />
A utility such as SD Sorter(https://www.trustfm.net/software/utilities/SDSorter.php) can be used to ensure files on the SD Card are properly ordered.<br />
The adapter provides for stereo output and you can attach an old-school pair of headphones (with volume pot) or, better yet, powered speakers.<br />

The adapter receives commands from the Vectrex via a crude SPI interface (CPOL=0, CPHA=0, MSB First).<br />
The pinouts are:<br />
![image](https://github.com/user-attachments/assets/eaedf890-28b8-4a1d-8ca9-6bde4c6b0099)

The Playing Flag is a signal that lets the Adapter know if a tune is playing or paused (there's no stop command).<br />
1 = Playing<br />
0 = Paused<br />
Since the MP3 Player takes some time to process a command, the signal can lag by up to 1 second from the Vectrex sending a command to play or pause.

![image](https://github.com/user-attachments/assets/ceebc8e3-ac21-416d-95fa-d5a03fe1049a)

The SPI serial data is 16 bits long (2 bytes) where:<br />
First Byte = Command<br />
Second Byte = Data<br />

![image](https://github.com/user-attachments/assets/4fae59f7-a693-4969-9eb5-d5fd61884835)

The Adpater uses a PI PICO coupled with a cheap but effective MP3 player module (https://diyables.io/products/mp3-player-module).<br />
<br />
<br />

Video of it in action:<br />
https://rumble.com/v6argvv-vectrex-mp3-player.html

