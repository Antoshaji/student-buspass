/*
 * READ NFC UID AND PRINT TO SERIAL
 * 
 * Library Required: MFRC522 (Install via Library Manager in Arduino IDE)
 * 
 * Wiring (Arduino Uno <-> RC522):
 * SDA (SS) -> Pin 10
 * SCK      -> Pin 13
 * MOSI     -> Pin 11
 * MISO     -> Pin 12
 * IRQ      -> Not Connected
 * GND      -> GND
 * RST      -> Pin 9
 * 3.3V     -> 3.3V (Using 5V will damage the module!)
 */

#include <SPI.h>
#include <MFRC522.h>

#define SS_PIN 10
#define RST_PIN 9
 
MFRC522 rfid(SS_PIN, RST_PIN); // Instance of the class

void setup() { 
  Serial.begin(9600);
  SPI.begin(); // Init SPI bus
  rfid.PCD_Init(); // Init MFRC522 

  Serial.println(F("Arduino Ready! Scan a tag..."));
}
 
void loop() {
  // Reset the loop if no new card present on the sensor/reader. This saves the entire process when idle.
  if ( ! rfid.PICC_IsNewCardPresent())
    return;

  // Verify if the NUID has been readed
  if ( ! rfid.PICC_ReadCardSerial())
    return;

  // Store NUID into nuidPICC array
  printHex(rfid.uid.uidByte, rfid.uid.size);
  Serial.println();

  // Halt PICC
  rfid.PICC_HaltA();

  // Stop encryption on PCD
  rfid.PCD_StopCrypto1();
  
  delay(1000); // 1 second delay to prevent multiple reads
}

/**
 * Helper routine to dump a byte array as hex values to Serial. 
 */
void printHex(byte *buffer, byte bufferSize) {
  for (byte i = 0; i < bufferSize; i++) {
    Serial.print(buffer[i] < 0x10 ? " 0" : " ");
    Serial.print(buffer[i], HEX);
  }
}
