#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <AnimatedGIF.h>
#include <SPI.h>
#include <TFT_eSPI.h>
#include <CST816S.h>



CST816S touch(6, 7, 13, 5);	

#include "C:\Users\nalba\OneDrive\Desktop\yeni_kol\homer.h"

AnimatedGIF gif;

TFT_eSPI tft = TFT_eSPI();

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic_1 = NULL;
BLECharacteristic* pCharacteristic_2 = NULL;

#define SERVICE_UUID        "8c30f045-683a-4777-8d21-87def63e4ef5"
#define CHARACTERISTIC_UUID_1 "d7be7b90-2423-4d6e-926d-239bc96bb2fd"
#define CHARACTERISTIC_UUID_2 "47524f89-07c8-43b6-bf06-a21c77bfdee8"
#define PASSKEY 999999

#define LED_BUILTIN 0
#define MAX_DATA_SIZE 819916 // Maksimum veri boyutu
uint8_t receivedData[MAX_DATA_SIZE]; // Gelen verileri tutacak dizi
int dataSize = 0; // Gelen veri boyutu
int dataSizeX = 0;
   int n_elements = 819916;
uint8_t * GIF_IMAGE ;



void setup() {
  Serial.begin(115200);

  pinMode (LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  

  tft.begin();

  tft.setRotation(0);
    touch.begin();
  tft.fillScreen(TFT_BLACK);

  gif.begin(BIG_ENDIAN_PIXELS);

  Serial.print(touch.data.version);
  Serial.print("\t");
  Serial.print(touch.data.versionInfo[0]);
  Serial.print("-");
  Serial.print(touch.data.versionInfo[1]);
  Serial.print("-");
  Serial.println(touch.data.versionInfo[2]);

  bleInit();
   GIF_IMAGE = (uint8_t *) ps_malloc (n_elements * sizeof (uint8_t));
}

int  a=0;
int x= 0;
void loop() {
  x++;
 //Serial.println(x);
if ( x%2 == 0){

  if (touch.available()) {
    Serial.print(touch.gesture());
    Serial.print("\t");
    Serial.print(touch.data.points);
    Serial.print("\t");
    Serial.print(touch.data.event);
    Serial.print("\t");
    Serial.print(touch.data.x);
    Serial.print("\t");
    Serial.println(touch.data.y);

  }
     if (touch.data.points==0) {
  pCharacteristic_1->setValue("No");
        delay(20);
     }
     else {
       pCharacteristic_1->setValue("Help");
        delay(20);
      
     }
     pCharacteristic_1->notify();
}
else {



   GIF_IMAGE = (uint8_t *) ps_malloc (n_elements * sizeof (uint8_t));

    //  Serial.println(digitalRead(LED_BUILTIN));



  
  if (a==0){
  
a=1;
for(int i=0; i<(sizeof(ucHomer));i++){
GIF_IMAGE[i] = (uint8_t)ucHomer[i];
//Serial.println(GIF_IMAGE[i]);
dataSizeX = 319916;
}}
//Serial.print("*******bitti dayı***********");


  // Put your main code here, to run repeatedly:
  //Serial.println(sizeof(GIF_IMAGE));

  if (dataSize == 0)
          {
  if (gif.open((uint8_t *)GIF_IMAGE, dataSizeX, GIFDraw))
  {
   // Serial.printf("Successfully opened GIF; Canvas size = %d x %d\n", gif.getCanvasWidth(), gif.getCanvasHeight());
    tft.startWrite(); // The TFT chip select is locked low
    while (gif.playFrame(true, NULL))
    {
      yield();
    }
    gif.close();
    tft.endWrite(); // Release TFT chip select for other SPI devices
  }
 }

free(GIF_IMAGE); //The allocated memory is freed.
  //     Serial.println((String)"PSRAM Size available (bytes): " +ESP.getFreePsram());


}


}

/////////////////////
//BLE Secure Server//
/////////////////////

class ServerCallback: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      Serial.println(" - ServerCallback - onConnect");
    };

    void onDisconnect(BLEServer* pServer) {
      Serial.println(" - ServerCallback - onDisconnect");
      digitalWrite(LED_BUILTIN, LOW);
    }

};



class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic_2) {
      std::string value = pCharacteristic_2->getValue();

      if (value.length() > 0) {
      //  Serial.println("***");
       // Serial.print("New value: ");
        for (int i = 0; i < value.length(); i++) {
         Serial.print(value[i]);
          // Eğer dizi kapasitesi aşılırsa yeni veriyi eklemeyi atla
          if (dataSize < MAX_DATA_SIZE) {
            GIF_IMAGE[dataSize] = value[i]; // Yeni veriyi diziye ekleyerek her seferinde bir sonraki indis kullanılır
            dataSize++; // Veri boyutunu bir arttır
          } else {
            Serial.println("Error: Data array is full!");
            break; // Dizinin kapasitesini aştıysak döngüden çık
          }
        }
       // Serial.println();
        //Serial.println("***");
      }

      else {
          if (dataSize != 0)
          {

            dataSizeX = dataSize;
          }

          dataSize =0;

      }
    }

   
};


class SecurityCallback : public BLESecurityCallbacks {

    uint32_t onPassKeyRequest() {
      return 000000;
    }

    void onPassKeyNotify(uint32_t pass_key) {}

    bool onConfirmPIN(uint32_t pass_key) {
      vTaskDelay(5000);
      return true;
    }

    bool onSecurityRequest() {
      return true;
    }

    void onAuthenticationComplete(esp_ble_auth_cmpl_t cmpl) {
      if (cmpl.success) {
        Serial.println("   - SecurityCallback - Authentication Success");
        digitalWrite(LED_BUILTIN, HIGH);
      } else {
        Serial.println("   - SecurityCallback - Authentication Failure*");
        pServer->removePeerDevice(pServer->getConnId(), true);
      }
      BLEDevice::startAdvertising();
    }

 

};

void bleSecurity() {
  esp_ble_auth_req_t auth_req = ESP_LE_AUTH_REQ_SC_MITM_BOND;
  esp_ble_io_cap_t iocap = ESP_IO_CAP_OUT;
  uint8_t key_size = 16;
  uint8_t init_key = ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK;
  uint8_t rsp_key = ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK;
  uint32_t passkey = PASSKEY;
  uint8_t auth_option = ESP_BLE_ONLY_ACCEPT_SPECIFIED_AUTH_DISABLE;
  esp_ble_gap_set_security_param(ESP_BLE_SM_SET_STATIC_PASSKEY, &passkey, sizeof(uint32_t));
  esp_ble_gap_set_security_param(ESP_BLE_SM_AUTHEN_REQ_MODE, &auth_req, sizeof(uint8_t));
  esp_ble_gap_set_security_param(ESP_BLE_SM_IOCAP_MODE, &iocap, sizeof(uint8_t));
  esp_ble_gap_set_security_param(ESP_BLE_SM_MAX_KEY_SIZE, &key_size, sizeof(uint8_t));
  esp_ble_gap_set_security_param(ESP_BLE_SM_ONLY_ACCEPT_SPECIFIED_SEC_AUTH, &auth_option, sizeof(uint8_t));
  esp_ble_gap_set_security_param(ESP_BLE_SM_SET_INIT_KEY, &init_key, sizeof(uint8_t));
  esp_ble_gap_set_security_param(ESP_BLE_SM_SET_RSP_KEY, &rsp_key, sizeof(uint8_t));
}
void bleInit() {
  BLEDevice::init("BLE-Secure-Server");
    
  BLEDevice::setEncryptionLevel(ESP_BLE_SEC_ENCRYPT);
  BLEDevice::setSecurityCallbacks(new SecurityCallback());

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallback());

  BLEService* pService = pServer->createService(SERVICE_UUID);
  pCharacteristic_1 = pService->createCharacteristic(
    CHARACTERISTIC_UUID_1,
    BLECharacteristic::PROPERTY_READ   |
    BLECharacteristic::PROPERTY_WRITE  |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic_2 = pService->createCharacteristic(
    CHARACTERISTIC_UUID_2,
    BLECharacteristic::PROPERTY_READ   |
    BLECharacteristic::PROPERTY_WRITE  |
    BLECharacteristic::PROPERTY_NOTIFY
  );

  pCharacteristic_1->setAccessPermissions(ESP_GATT_PERM_READ_ENCRYPTED | ESP_GATT_PERM_WRITE_ENCRYPTED);
  pCharacteristic_2->setAccessPermissions(ESP_GATT_PERM_READ_ENCRYPTED | ESP_GATT_PERM_WRITE_ENCRYPTED);

  // pCharacteristic_2'ye geri arama ataması yap
  pCharacteristic_2->setCallbacks(new MyCallbacks());

  pService->start();

  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();

  bleSecurity();
}