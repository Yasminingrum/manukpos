# MANUK - Manajemen Keuangan UMKM

## Daftar Isi
1. [Pendahuluan](#pendahuluan)
2. [Arsitektur Aplikasi](#arsitektur-aplikasi)
3. [Model Data](#model-data)
4. [Modul dan Fitur](#modul-dan-fitur)
5. [Layanan (Services)](#layanan-services)
6. [Utility](#utility)
7. [Antarmuka Pengguna](#antarmuka-pengguna)

## Pendahuluan

Aplikasi Manajemen Keuangan UMKM adalah solusi komprehensif untuk mengelola operasi bisnis kecil sehari-hari. Dikembangkan menggunakan Flutter, aplikasi ini menyediakan berbagai fitur termasuk:

- Point of Sale (POS)
- Manajemen inventaris
- Pelacakan pengeluaran
- Manajemen pelanggan dan pemasok
- Pelaporan keuangan dan penjualan
- Manajemen multi-cabang

Aplikasi ini dirancang untuk bekerja secara online maupun offline dengan kemampuan sinkronisasi data.

## Arsitektur Aplikasi

Aplikasi ini mengikuti struktur modular dengan komponen-komponen yang terpisah secara jelas berdasarkan fungsinya:

```
lib/
├── main.dart                    # Titik masuk aplikasi
├── app.dart                     # Konfigurasi aplikasi
├── config/                      # Konfigurasi aplikasi
├── models/                      # Model data
├── screens/                     # Layar UI
├── services/                    # Layanan bisnis
├── utils/                       # Fungsi utilitas
└── widgets/                     # Komponen UI yang dapat digunakan kembali
```

### Konfigurasi (`config/`)

Direktori ini berisi konfigurasi aplikasi, termasuk:
- `theme.dart`: Pengaturan tema aplikasi
- `routes.dart`: Definisi rute navigasi
- `register_expense_module.dart`: Registrasi modul pengeluaran
- `constants.dart`: Konstanta yang digunakan di seluruh aplikasi

## Model Data

Folder `models/` berisi definisi struktur data inti aplikasi:

| Model | Deskripsi |
|-------|-----------|
| `user.dart` | Model data pengguna aplikasi |
| `transaction.dart` | Model untuk transaksi penjualan dan pembelian |
| `product.dart` | Model untuk produk yang dijual atau dibeli |
| `branch.dart` | Representasi cabang atau toko |
| `business.dart` | Entitas bisnis yang menggunakan aplikasi |
| `category.dart` | Kategori untuk produk dan pengeluaran |
| `customer.dart` | Data pelanggan |
| `expense.dart` | Pengeluaran bisnis |
| `inventory.dart` | Status inventaris |
| `inventory_movement.dart` | Pergerakan barang dalam inventaris |
| `payment.dart` | Detail metode pembayaran dan status |
| `stock_opname.dart` | Penghitungan stok fisik |
| `supplier.dart` | Data pemasok |
| `transaction_item.dart` | Item baris dalam transaksi |

## Modul dan Fitur

### 1. Modul Transaksi
Modul ini mencakup fitur untuk menangani operasi transaksi sehari-hari:
- Point of Sale (POS)
- Pembelian
- Riwayat transaksi
- Detail transaksi

File terkait:
```
screens/transactions/
├── transaction_detail_screen.dart
├── purchasing_screen.dart
├── history_screen.dart
└── pos_screen.dart
```

### 2. Modul Autentikasi
Menangani proses masuk, pendaftaran, dan pemulihan kata sandi pengguna:
```
screens/auth/
├── login_screen.dart
├── register_screen.dart
└── forgot_password_screen.dart
```

### 3. Modul Pelanggan
Pengelolaan data pelanggan:
```
screens/customers/
├── customer_list.dart
├── customer_detail.dart
└── customer_form.dart
```

### 4. Modul Dashboard
Tampilan ringkasan bisnis dan metrik utama:
```
screens/dashboard/
└── dashboard_screen.dart
```

### 5. Modul Inventaris
Pengelolaan produk dan stok:
```
screens/inventory/
├── product_list.dart
├── product_detail.dart
├── product_form.dart
└── stock_opname.dart
```

### 6. Modul Laporan
Berbagai laporan bisnis:
```
screens/reports/
├── sales_report.dart
├── inventory_report.dart
├── expense_report.dart
├── financial_report.dart
└── reports_module.dart
```

### 7. Modul Pengaturan
Pengaturan aplikasi dan profil bisnis:
```
screens/settings/
├── user_management.dart
├── business_profile.dart
└── app_settings.dart
```

### 8. Modul Pemasok
Pengelolaan data pemasok:
```
screens/suppliers/
├── supplier_list.dart
├── supplier_detail.dart
└── supplier_form.dart
```

## Layanan (Services)

Folder `services/` mengandung logika bisnis utama aplikasi:

| Layanan | Deskripsi |
|---------|-----------|
| `inventory_service.dart` | Manajemen inventaris, termasuk pergerakan stok |
| `expense_service.dart` | Pelacakan dan pengelolaan pengeluaran |
| `database_service.dart` | Operasi database lokal |
| `auth_service.dart` | Autentikasi dan otorisasi pengguna |
| `transaction_service.dart` | Pemrosesan transaksi penjualan dan pembelian |
| `api_service.dart` | Koneksi ke API eksternal |
| `product_service.dart` | Pengelolaan produk |
| `shared_preferences_service.dart` | Penyimpanan preferensi lokal |
| `sync_service.dart` | Sinkronisasi data antara perangkat dan server |

## Utility

Folder `utils/` berisi berbagai fungsi utilitas untuk mendukung aplikasi:

| Utility | Deskripsi |
|---------|-----------|
| `security_utils.dart` | Fungsi keamanan |
| `validation_utils.dart` | Validasi formulir |
| `number_utils.dart` | Pemformatan angka |
| `image_utils.dart` | Penanganan gambar |
| `print_utils.dart` | Pencetakan struk |
| `locale_utils.dart` | Lokalisasi |
| `file_utils.dart` | Operasi file |
| `barcode_utils.dart` | Pemindaian barcode/QR |
| `network_utils.dart` | Konektivitas jaringan |
| `date_utils.dart` | Pemformatan tanggal |
| `db_utils.dart` | Utilitas database |
| `device_utils.dart` | Fitur khusus perangkat |
| `export_utils.dart` | Ekspor data |
| `formatters.dart` | Pemformatan teks |
| `helpers.dart` | Fungsi pembantu umum |
| `permission_utils.dart` | Penanganan izin |
| `sync_utils.dart` | Pembantu sinkronisasi |
| `toast_utils.dart` | Notifikasi toast |
| `ui_utils.dart` | Pembantu UI |

## Antarmuka Pengguna

Folder `widgets/` berisi komponen UI yang dapat digunakan kembali:

### Komponen Visualisasi Data
- `cash_flow_chart.dart`: Visualisasi arus kas
- `sales_chart.dart`: Visualisasi penjualan
- `inventory_movement_chart.dart`: Visualisasi pergerakan inventaris
- `chart/bar_chart.dart`: Komponen diagram batang
- `chart/pie_chart.dart`: Komponen diagram lingkaran

### Komponen UI Umum
- `custom_app_bar.dart`: App bar kustom
- `custom_button.dart`: Tombol bergaya
- `custom_drawer.dart`: Drawer navigasi kustom
- `custom_text_field.dart`: Field input teks
- `confirmation_dialog.dart`: Dialog konfirmasi
- `loading_indicator.dart`: Animasi loading
- `loading_overlay.dart`: Overlay layar loading
- `empty_state.dart`: Placeholder keadaan kosong

### Komponen UI Khusus
- `dashboard_card.dart`: Kartu info dashboard
- `report_summary_card.dart`: Kartu ringkasan laporan
- `customer_selector.dart`: Widget pemilihan pelanggan
- `date_range_picker.dart`: Pemilihan rentang tanggal
- `export_button.dart`: Fungsionalitas ekspor
- `pos_cart_item.dart`: Item keranjang POS
- `product_item.dart`: Item daftar produk
- `recent_transaction_item.dart`: Transaksi terbaru
- `report_filter_chip.dart`: Filter laporan