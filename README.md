# JenniferFelix — Controle de Vendas 💄

Aplicativo completo de gestão para revendedoras de cosméticos (Avon, Natura, Eudora, O Boticário e outras).

## ✨ Funcionalidades

- **Dashboard** — Resumo completo: vendas, recebimentos, lucro estimado, estoque
- **Clientes** — Cadastro completo com histórico de compras e pagamentos
- **Produtos** — Catálogo com foto, controle de estoque e alerta de mínimo
- **Vendas** — Registro de vendas à vista e parceladas
- **Parcelamentos** — Controle de parcelas pagas, pendentes e atrasadas
- **Pagamentos** — Registro e histórico completo
- **Relatórios** — Gráficos de vendas, top clientes e produtos mais vendidos
- **Backup** — Automático a cada 7 dias, criptografado, com exportação para iCloud/Arquivos
- **Segurança** — PIN local + biometria + bloqueio automático
- **100% Offline** — Nenhuma conexão com internet necessária

## 🛠 Stack

- **Flutter** 3.x (Dart)
- **SQLite** via `sqflite` — banco local
- **Provider** — gerenciamento de estado
- **local_auth** — biometria (Face ID / Touch ID)
- **encrypt** — backup criptografado AES-256
- **fl_chart** — gráficos nos relatórios
- **flutter_local_notifications** — alertas de vencimento e estoque

## 📱 Como compilar

### Pré-requisitos

- Flutter SDK 3.x instalado
- Android Studio ou Xcode (para iOS)
- Conta Apple Developer (para TestFlight)

### Android (APK)

```bash
flutter pub get
flutter build apk --release
# APK em: build/app/outputs/flutter-apk/app-release.apk
```

### Android (App Bundle — Google Play)

```bash
flutter build appbundle --release
```

### iOS (TestFlight)

```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
# Abrir ios/Runner.xcworkspace no Xcode
# Product > Archive > Distribute App > TestFlight
```

### Configurar Bundle ID iOS

No Xcode, altere `com.jenniferfelix.app` para o seu Bundle ID registrado na Apple Developer.

## 📂 Estrutura do Projeto

```
lib/
├── main.dart                    # Ponto de entrada + Splash Screen
├── theme/                       # Cores e tema do app
├── models/                      # Client, Product, Sale, Installment, Payment
├── database/                    # SQLite DAOs
├── providers/                   # Estado com Provider
├── screens/
│   ├── auth/                    # Login + Setup PIN
│   ├── dashboard/               # Tela inicial
│   ├── clients/                 # Lista, formulário e detalhes
│   ├── products/                # Lista e formulário
│   ├── sales/                   # Lista, formulário e detalhes
│   ├── installments/            # Controle de parcelas
│   ├── reports/                 # Relatórios com gráficos
│   ├── backup/                  # Backup e restauração
│   └── settings/                # Configurações e segurança
├── utils/
│   ├── backup_service.dart      # Serviço de backup criptografado
│   └── formatters.dart          # Formatadores de data/moeda
└── widgets/                     # Widgets reutilizáveis
```

## 🔐 Segurança

- PIN local com hash SHA-256
- Biometria (Face ID / Touch ID)
- Bloqueio automático por inatividade
- Backups criptografados com AES-256
- Dados armazenados apenas no dispositivo

## 📦 Backup

Os backups são salvos em:
- **Android:** `/storage/emulated/0/JenniferFelix_Backups/`
- **iOS:** Pasta de documentos do app (acessível via Arquivos)

Formato: `.jfb` (Jennifer Felix Backup) — criptografado AES-256.

---

Desenvolvido com 💗 para revendedoras de beleza
