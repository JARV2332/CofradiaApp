# 📱 Guía para Construcción iOS

## 🔧 Requisitos Previos
1. **Mac con macOS 12.0 o superior**
2. **Xcode 14.0 o superior** (App Store)
3. **Flutter instalado** en el Mac
4. **CocoaPods** (`sudo gem install cocoapods`)

## 📂 Preparación del Proyecto

### 1. Transferir el Proyecto
```bash
# Copiar todo el proyecto a tu Mac
scp -r "cofradia_app" usuario@mac:/ruta/destino/
```

### 2. Instalar Dependencias iOS
```bash
cd cofradia_app
flutter pub get
cd ios
pod install
cd ..
```

## 🏃‍♂️ Ejecución y Pruebas

### Simulador iOS
```bash
# Listar simuladores disponibles
flutter devices

# Ejecutar en simulador
flutter run -d "iPhone 15 Pro"

# Ejecutar con hot reload
flutter run -d ios --hot
```

### Dispositivo Físico iOS
```bash
# Conectar iPhone vía USB
# Confiar en el computador en el iPhone
flutter run -d "iPhone de [Nombre]"
```

## 🏗️ Construcción para Distribución

### Construcción de Desarrollo
```bash
# Generar app para testing
flutter build ios --debug

# Generar app optimizada
flutter build ios --release
```

### Construcción IPA (App Store)
```bash
# Generar IPA para distribución
flutter build ipa

# IPA con configuración específica
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

## 📍 Ubicaciones de Archivos

### Archivo .app (para simulador)
```
build/ios/iphonesimulator/Runner.app
```

### Archivo IPA (para distribución)
```
build/ios/ipa/cofradia_app.ipa
```

## ⚙️ Configuraciones Adicionales

### 1. Configurar Bundle ID
Editar `ios/Runner/Info.plist`:
```xml
<key>CFBundleIdentifier</key>
<string>com.tuempresa.cofradia_app</string>
```

### 2. Configurar Permisos
Para QR Scanner en `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Esta app necesita acceso a la cámara para escanear códigos QR</string>
```

### 3. Configurar Iconos
Agregar iconos en `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## 🔐 Certificados y Provisioning

### Desarrollo
1. Abrir `ios/Runner.xcworkspace` en Xcode
2. Seleccionar tu Apple ID en "Signing & Capabilities"
3. Xcode manejará automáticamente los certificados

### Distribución
1. Crear certificados en [developer.apple.com](https://developer.apple.com)
2. Descargar provisioning profiles
3. Configurar en Xcode o via command line

## 📤 Distribución

### TestFlight (Beta)
```bash
# Construir y subir a TestFlight
flutter build ipa
# Usar Xcode Organizer o Application Loader
```

### App Store
```bash
# Mismo proceso que TestFlight
# Pero marcar para producción en App Store Connect
```

## 🔍 Debugging iOS

### Logs del Dispositivo
```bash
# Ver logs en tiempo real
flutter logs

# Logs específicos de iOS
instruments -t "System Trace" -D trace.trace
```

### Debugging en Xcode
1. Abrir `ios/Runner.xcworkspace`
2. Ejecutar desde Xcode para debugging nativo
3. Usar breakpoints y profiler de Xcode

## 📱 Funciones Específicas iOS

Tu app de cofradía funcionará igual en iOS:
- ✅ Gestión de cofrades
- ✅ Generación de carnets PDF
- ✅ Códigos QR
- ✅ Datos offline
- ✅ Interfaz nativa iOS (Material adaptada a Cupertino)

## ⚠️ Consideraciones Especiales

1. **Permisos**: iOS requiere declarar permisos explícitamente
2. **Iconos**: iOS tiene múltiples tamaños de iconos requeridos
3. **Certificados**: Necesitas cuenta de Apple Developer para dispositivos físicos
4. **Review Process**: App Store tiene proceso de revisión (1-7 días)

## 🎯 Resumen Rápido

Para tu app de cofradía en iOS:
1. **Desarrollo**: Mac + Xcode + `flutter build ios`
2. **Testing**: Simulador iOS o dispositivo con certificado dev
3. **Distribución**: `flutter build ipa` + App Store Connect
4. **Resultado**: Archivo .ipa listo para instalar en iPhones

¡La misma funcionalidad, interfaz nativa iOS!