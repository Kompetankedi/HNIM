<div align="center">
  
# 🌐 Homelab Network Inventory Manager (HNIM)

Homelab ortamları (ev sunucuları) için özel olarak tasarlanmış yepyeni, şık ve kendi sunucunuzda (self-hosted) barındırmak için biçilmiş kaftan bir ağ envanter takip uygulaması. Tamamen "Dark Mode" arayüze, otomatik sağlık testlerine sahip paneli ile sunucularınızı, router'larınızı, ev otomasyon cihazlarınızı ve mobil uçlarınızı anlık olarak takip edin.

![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![NodeJS](https://img.shields.io/badge/Backend-Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)
![MSSQL](https://img.shields.io/badge/Database-MSSQL-CC292B?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Docker](https://img.shields.io/badge/Deployment-Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)

*[Read in English 🇬🇧/🇺🇸](#english-version-english)*

</div>

---

## ✨ Özellikler

- **📱 Premium Çapraz-Platform Uygulama**: Flutter ile geliştirilmiştir. Neon durum göstergelerine ve akıcı degrade efektlere (radial gradients) sahip şık "glassmorphism" (buzlu cam) koyu tema tasarımı.
- **🔄 Otomatik Arka Plan Monitörü (Cron Job)**: Node.js backend'i her 5 dakikada bir veri tabanına kayıtlı cihazlara asenkron "ping" sinyalleri atarak, sunucularınızın Çevrimiçi/Çevrimdışı (Online/Offline) durumlarını ve Son Görülme (Last Seen) zaman damgalarını kendi kendine otomatik olarak günceller.
- **📷 QR / Barkod Okuyucu (Kamera Entegrasyonu)**: Cihazlarınızın üzerinde yazan inanılmaz uzun Seri Numaralarını veya MAC Adreslerini elle girmek yerine telefonunuzun veya tabletinizin kamerasını kullanarak anında okutun! (Canlı flaş/ışık kontrolü ve ön/arka kamera değiştirme desteği içerir).
- **🌍 Çift Dil Desteği (Bilingual)**: Hem **Türkçe** hem de **İngilizce** desteği sunar. Uygulamayı yeniden başlatmaya gerek kalmadan "Ayarlar" sekmesinden anında dil değiştirebilirsiniz.
- **🏷️ Özel Ek Kategoriler**: Standart Cihaz tipleriyle sınırlı kalmayın! Ayarlar kısmına gidip virgülle ayırarak yepyeni kategoriler oluşturabilirsiniz (örn: Switch, Güvenlik Kamerası, 3D Yazıcı).
- **🛠️ Dinamik API Adresi Bağlantısı**: Tüm mobil cihazları, sadece tek bir URL adresiyle yerel ev ağınızdaki Backend sunucunuza kolayca bağlayın.
- **🐳 Docker ve CasaOS Uyumlu**: Node.js API ve dedike "Microsoft SQL Server" (MSSQL) veritabanı içeren Docker Compose paketidir.

---

## 🏗️ Kullanılan Teknolojiler

### Frontend (Mobil İstemci)
- **Çerçeve**: Flutter (Dart)
- **Durum Yönetimi (State)**: Provider
- **Sistem İçi Hafıza**: Ayarlar ve dil seçenekleri için `shared_preferences`
- **Kritik Paketler**: `http` (Ağ), `mobile_scanner` (QR Kamera), `permission_handler`

### Backend (API Sunucusu ve Monitör)
- **Çalışma Ortamı**: Node.js
- **Çerçeve (Framework)**: Express.js
- **Veritabanı Sürücüsü**: `mssql`
- **Arka Plan Döngüsü**: Yerel `child_process.exec` üzerinden asenkron "ping" destekli zamanlanmış (setInterval) veri tabanı güncelleyicisi.
- **Güvenlik / Çevresel P**: `cors`, `dotenv`

### Veritabanı ve Devops
- **Veritabanı Motoru**: Microsoft SQL Server (MSSQL) `mcr.microsoft.com/mssql/server:2022-latest`
- **Dağıtım (Deployment)**: Docker, Docker Compose

---

## 🚀 Başlangıç ve Kurulum (Türkçe)

### Gereksinimler
- Backend için [Docker](https://docs.docker.com/get-docker/) ve [Docker Compose](https://docs.docker.com/compose/install/)
- Frontend için [Flutter SDK](https://docs.flutter.dev/get-started/install) 
- Evinizdeki bir bilgisayar, Raspberry Pi veya CasaOS vb. kurulu olan herhangi bir Homelab sistemi.

### 1️⃣ Backend Kurulumu (Docker)
Node.js ve MSSQL veritabanı birbirine konteyner üzerinden bağlanacak şekilde tamamen yapısaldır (zero-friction).

1. Projeyi klonlayın:
   ```bash
   git clone https://github.com/yourusername/HNIM.git
   cd HNIM
   ```
2. Projenin ana dizininde (`HNIM/`) bir `.env` dosyası oluşturun ve aşağıdaki değişkenleri ekleyin (şifreleri kendinize göre yapılandırabilirsiniz):
   ```env
   MSSQL_SA_PASSWORD=HNIM_Strong_Pass_2024!
   ACCEPT_EULA=Y
   DB_HOST=mssql
   DB_USER=sa
   DB_PASSWORD=HNIM_Strong_Pass_2024!
   DB_NAME=HNIM
   PORT=3055
   ```
3. Docker Compose ile başlatın:
   ```bash
   docker compose up --build -d
   ```
4. Sadece bitti! Express API `http://localhost:3000` portunda, Veritabanı ise `1433` portunda çalışmaya başlayacak. Tablolarınız otomatik çalıştırılan SQL şemasıyla sizin için ilk açılışta yaratılacak. 

### 2️⃣ Frontend (Uygulama) Kurulumu (Flutter)
Mobil uygulamayı doğrudan fiziksel bir cihaza (Android/iOS) paketlemek için:

1. Frontend dizinine inin:
   ```bash
   cd frontend
   ```
2. Gerekli kütüphaneleri ve Flutter paketlerini indirin:
   ```bash
   flutter pub get
   ```
3. Cihazınızı USB ya da Wi-Fi üzerinden (Developer Mode) cihazına bağlayın ve fırlatın!:
   ```bash
   flutter run
   ```
> *Not: Eğer bunu bir iOS cihaza paketliyorsanız, Xcode kullanıyor olmanız gerekir (zaten Mac kullandığınız için). QR kodu okuyucu paket `mobile_scanner`, uygulamanın `Info.plist` ve `AndroidManifest.xml` dosyalarındaki kamera izin taleplerine ihtiyaç duyar (Bu repoda sizin için özenle konfigüre edilmiştir).*

---

## ⚙️ Uygulama İçi (Mobil) Ayarlar

İlk kez uygulamaya başarıyla girdiğinizde ana ekranınızdaki verilerin gelmesi için backend URL adresini programa belirtmeniz gerekir:
1. Sağ üst köşedeki ⚙️ çark (Ayarlar) butonuna tıklayın.
2. Açılan ekranda "Sunucu URL" kısmına Homelab Sunucunuzun yerel ip adresini (ve port 3000 i) yazınız. (örn: `http://192.168.1.100:3000`). En sona `/` koymadığınıza emin olunuz.
3. Arka plan servislerinin sizi görüp görmediğini sınamak için **Bağlantıyı Test Et** butonuna tıklayın.
4. Başarılı (yeşil bar) ibaresini aldıktan sonra, en alttaki "Ayarları Kaydet" kısmına (Save Settings) tıklayınız.

---

## 📷 Ekran Görüntüleri

| Dashboard (Karanlık Tema) | Envanter Listesi (Gelişmiş Filtre) | Ayarlar, URL ping, Dil ve Custom Kategoriler |
| :---: | :---: | :---: |
| *<img width="420" height="987" alt="resim" src="https://github.com/user-attachments/assets/a52eb3a7-94e8-4b77-9f0c-befb0e1492c7" />
* | *<img width="426" height="991" alt="resim" src="https://github.com/user-attachments/assets/e6e2f528-188a-4fe3-b489-c6980488ae63" />
* |

---
---

<br>
<br>

<div align="center" id="english-version-english">

# 🌐 Homelab Network Inventory Manager (HNIM) (English)

A sleek, self-hosted, full-stack network inventory and monitoring application designed specifically for Homelab environments. Keep track of your servers, routers, IoT devices, and mobiles with automated health checks and an exclusively premium dark-mode interface.

</div>

---

## ✨ Features

- **📱 Premium Cross-Platform App**: Built with Flutter. Beautiful glassmorphic dark-theme UI featuring glowing status indicators and smooth gradients.
- **🔄 Automated Background Monitoring (Cron)**: The Node.js backend operates a persistent 5-minute interval cron job, continuously executing concurrent system `ping` requests to all registered devices to automatically track Online/Offline states and `LastSeen` timestamps.
- **📷 QR / Barcode Scanner Integration**: Instantly grab long Serial Numbers or MAC Addresses natively from your device's camera. Includes live Torch/Flashlight controls and camera switching.
- **🌍 Full Localization (Bilingual)**: Out-of-the-box support for both **English** and **Türkçe**. Instantly switch languages via the Settings menu without requiring an application restart.
- **🏷️ Custom Categories**: Not limited to standard categories! Go to Settings and add entirely customized comma-separated hardware categories (e.g., Switch, Camera, 3D Printer).
- **🛠️ Remote API Configuration**: Dynamically bind your client app to your backend API. Includes an automated **Test Connection** ping explicitly designed to verify reachability.
- **🐳 Docker & CasaOS Ready**: Contains comprehensive Docker Compose infrastructure handling the Node.js backend tying straight into a dedicated Microsoft SQL Server (MSSQL) container.

---

## 🏗️ Technology Stack

### Frontend (Mobile & Web Client)
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Storage**: `shared_preferences` for localized persistent settings
- **Packages**: `http`, `mobile_scanner` (Camera QR integration), `permission_handler`

### Backend (API & Worker)
- **Environment**: Node.js
- **Framework**: Express.js
- **Database Driver**: `mssql`
- **Background Tasks**: Native `setInterval` combined with `child_process.exec` (System Ping)
- **Middleware**: `cors`, `dotenv`

### Database & DevOps
- **Database**: Microsoft SQL Server (MSSQL) `mcr.microsoft.com/mssql/server:2022-latest`
- **Deployment**: Docker, Docker Compose

---

## 🚀 Getting Started

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) (Backend & DB)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Frontend)
- A Homelab environment (CasaOS, Proxmox, TrueNAS, or just a Raspberry Pi / standard Linux host).

### 1️⃣ Backend Setup (Docker)
The backend service and the MSSQL database are fully containerized for a zero-friction deployment.

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/HNIM.git
   cd HNIM
   ```
2. Create a `.env` file in the root directory (`HNIM/`) and add the following required environment variables (change passwords as needed):
   ```env
   MSSQL_SA_PASSWORD=HNIM_Strong_Pass_2024!
   ACCEPT_EULA=Y
   DB_HOST=mssql
   DB_USER=sa
   DB_PASSWORD=HNIM_Strong_Pass_2024!
   DB_NAME=HNIM
   PORT=3055
   ```
3. Start the services via Docker Compose:
   ```bash
   docker compose up --build -d
   ```
4. The Express API will now be rolling on `http://localhost:3000` (or your host IP), and the Database on port `1433`. The database schemas and `Devices` table are automatically initialized on the first boot! 🎉

### 2️⃣ Frontend Setup (Flutter)
If you wish to compile the mobile application directly to your physical device:

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Connect your Android or iOS device via USB or Wi-Fi debugging and launch:
   ```bash
   flutter run
   ```
> *Note: iOS compilations require Xcode to be installed. The `mobile_scanner` dependency for the QR codes dynamically requires camera hardware definitions injected directly into `Info.plist` and `AndroidManifest.xml` (already configured in this repository).*

---

## ⚙️ Configuration

When you first launch the **HNIM** mobile app, you must connect it to your backend:
1. Tap the ⚙️ **Settings** gear icon in the top right of the Dashboard.
2. In the **Server URL** input, enter your host system's IP (e.g., `http://192.168.1.100:3000`). Make sure you omit the trailing slash.
3. Tap **Test Connection** to execute a soft ping validating the path between the phone and the backend.
4. If successful, tap **Save Settings**. The application will instantly re-sync its state against your active local backend.

---

## 🤝 Contributing
Contributions are always welcome! Feel free to open an Issue if you encounter bugs or want to request a feature. If you have code to submit, please open a Pull Request!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

<p align="center">Made with ❤️ for Homelab enthusiasts running on CasaOS & Docker.</p>
