<div align="center">

<img src="assets/images/app_logo.png" alt="Logo de DIME" width="120" />

# DIME

**Toma el control y asigna cada dólar con confianza.**

Aplicación móvil de presupuesto personal basada en el método de asignación de cada dólar (estilo YNAB),
con vinculación bancaria simulada mediante Open Banking.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart_3-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Material 3](https://img.shields.io/badge/Material_3-757575?style=for-the-badge&logo=materialdesign&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

</div>

---

## Tabla de contenido

- [Sobre el proyecto](#sobre-el-proyecto)
- [Funcionalidades](#funcionalidades)
- [Tecnologías](#tecnologías)
- [Arquitectura](#arquitectura)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Puesta en marcha](#puesta-en-marcha)
- [Seguridad y privacidad](#seguridad-y-privacidad)
- [Estado del proyecto](#estado-del-proyecto)

---

## Sobre el proyecto

DIME ayuda a las personas a darle un destino a cada dólar que reciben. El usuario registra sus ingresos,
**asigna** el dinero a categorías (vivienda, alimentación, transporte…) y la app le muestra cuánto le queda
disponible en cada una, alertándolo cuando se excede. La meta es llevar el **"Dinero para asignar"** a $0.

Las transacciones pueden registrarse manualmente o importarse desde un **banco simulado** que reproduce el
flujo real de Open Banking: autorización OAuth 2.0, consulta de cuentas y sincronización incremental de
movimientos, con categorización semiautomática según el comercio.

> [!NOTE]
> La conexión bancaria es una **simulación** construida con [Mockoon](https://mockoon.com/). DIME no se conecta
> con ninguna institución financiera real, y los nombres de bancos se usan solo con fines ilustrativos.

---

## Funcionalidades

### Presupuesto
- **Dinero para asignar** del mes y botón de **asignación rápida**.
- **Categorías** personalizables: color, ícono, reordenamiento por arrastre y plantillas sugeridas.
- **Principales prioridades** en Inicio, con barra de progreso y alerta de categoría excedida.
- **Transacciones manuales** de ingreso y gasto.

### Open Banking simulado
- Vinculación con 6 bancos panameños simulados mediante **OAuth 2.0** (con verificación del parámetro `state`).
- Hasta 2 cuentas por usuario: cuenta corriente o de ahorros y tarjeta de crédito.
- **Sincronización incremental** con cursor y sin duplicados.
- **Categorización semiautomática**: DIME aprende la categoría de cada comercio cuando el usuario la confirma.

### Análisis
- **Dashboard** con gastos por categoría, ingresos vs. gastos y **patrimonio neto** (3, 6 o 12 meses).
- Alerta cuando, en promedio, los gastos superan a los ingresos.
- **Informe financiero en PDF** (1, 3, 6 o 12 meses) generado en el dispositivo, con gráficas y texto personalizado.

### Cuenta y seguridad
- Registro con **verificación de correo** por código y aceptación de **términos y condiciones**.
- **Verificación en dos pasos** por correo electrónico (opcional).
- **Inicio de sesión con huella** o rostro.
- **Recuperación de contraseña** con código de un solo uso.
- Perfil con **foto**, cambio de contraseña y **eliminación de la cuenta** con encuesta de salida y correo de confirmación.
- **Ayuda y soporte**: preguntas frecuentes, envío de reportes y tour guiado.

### Accesibilidad
- Modos de color para **protanopía**, **deuteranopía** y **tritanopía**. Cambian el tema completo
  (no solo las gráficas), con paletas validadas por simulación de daltonismo (Machado et al., 2009).
- **Tour guiado** para usuarios nuevos.

---

## Tecnologías

| Capa | Tecnología |
|---|---|
| App móvil | Flutter, Dart 3, Material 3 |
| Estado | `provider` (`ChangeNotifier`) |
| Gráficas | `fl_chart` |
| Backend | Supabase: PostgreSQL, Auth, Storage, Row Level Security, triggers y funciones |
| Correo | Brevo (SMTP para la autenticación, API para el correo de despedida desde `pg_net`) |
| Banco simulado | Mockoon (API REST con OAuth 2.0) |
| Cliente HTTP | `http` |
| Seguridad local | `flutter_secure_storage` (Android Keystore / iOS Keychain), `local_auth` |
| Informes | `pdf`, `printing` |
| Otros | `intl`, `shared_preferences`, `image_picker`, `flutter_svg` |

---

## Arquitectura

DIME sigue un **MVVM simplificado** combinado con el patrón **Repository**:

```text
 Vistas (features/*)  ──llaman──▶  AppState (state/)  ──usa──▶  DimeRepository ──HTTPS──▶ Supabase
        ▲                              │                         BankApi       ──HTTP───▶ Mockoon
        └────── notifyListeners() ─────┘
```

| Capa | Ubicación | Responsabilidad |
|---|---|---|
| **View** | `lib/features/` | Dibujar la interfaz y reaccionar a los eventos del usuario |
| **ViewModel** | `lib/state/app_state.dart` | Estado en memoria, cálculos (disponible, patrimonio, promedios) y notificación de cambios |
| **Model / Repository** | `lib/data/` | Modelos inmutables y único punto de acceso a Supabase y al banco |

Otras decisiones de diseño:
- **Interfaz optimista** con una cola de escrituras serializada: los cambios se ven al instante y se guardan en orden.
- **Seguridad en la base de datos**: cada tabla tiene políticas RLS que filtran por `auth.uid()`.
- Un **trigger** crea, al registrarse, el perfil, las categorías predeterminadas y el presupuesto del mes.

---

## Estructura del proyecto

```text
lib/
├── main.dart              # Punto de entrada: Supabase, accesibilidad y tema
├── core/                  # Código compartido
│   ├── accessibility/     # Modos de daltonismo
│   ├── config/            # Supabase y URL del banco simulado
│   ├── constants/         # Plantillas de categorías y comercios conocidos
│   ├── theme/             # Tema Material 3, colores e íconos
│   ├── utils/             # Validadores, formatos, huella y mensajes de error
│   └── widgets/           # Widgets reutilizables
├── data/
│   ├── models/            # Perfil, Categoria, Transaccion, Presupuesto…
│   ├── repositories/      # Acceso a Supabase
│   └── services/          # Banco simulado, tokens, cuenta y verificación en dos pasos
├── state/                 # AppState (estado global y lógica de negocio)
├── navigation/            # Barra de navegación inferior
└── features/              # Una carpeta por funcionalidad
    ├── auth/              # Login, registro, verificación, dos pasos, recuperación
    ├── home/              # Inicio
    ├── categories/        # Categorías y asignación rápida
    ├── dashboard/         # Gráficas
    ├── transactions/      # Transacciones manuales y revisión
    ├── bank/              # Vinculación con el banco simulado
    ├── report/            # Informe PDF
    ├── profile/  account/ settings/  support/  legal/  tour/  accessibility/
```

---

## Puesta en marcha

### Requisitos
- [Flutter](https://docs.flutter.dev/get-started/install) (canal estable, Dart 3)
- Un proyecto en [Supabase](https://supabase.com/)
- [Mockoon](https://mockoon.com/) (escritorio o CLI) para el banco simulado
- Android Studio o un dispositivo Android

### 1. Clonar e instalar dependencias
```bash
git clone https://github.com/JDH-CS/Proyecto-DIME.git
cd DIME
flutter pub get
```

### 2. Configurar Supabase
1. Coloca la URL del proyecto y la **publishable key** en `lib/core/config/supabase_config.dart`.
2. Ejecuta los scripts SQL del proyecto en el SQL Editor, en orden:

   | Script | Contenido |
   |---|---|
   | `01_esquema_dime.sql` | Tablas, restricciones, triggers, RLS y permisos |
   | `04_colores_categorias.sql` | Paleta de categorías y trigger de registro |
   | `05_perfil_foto_y_soporte.sql` | Bucket privado `avatars` y reportes de soporte |
   | `08_verificacion_dos_pasos.sql` | Columna y permiso de la verificación en dos pasos |
   | `09_eliminar_cuenta.sql` | Eliminación de cuenta y correo de despedida |
   | `03_…` / `06_…` | *(Opcional)* Datos de demostración |

3. En **Authentication**:
   - Activa **Confirm email**.
   - Configura el SMTP de Brevo.
   - Usa plantillas con `{{ .Token }}` para *Confirm signup*, *Reset password* y *Magic Link*.

> [!IMPORTANT]
> Nunca uses la clave `service_role` dentro de la app ni la subas al repositorio. La API key de Brevo
> se guarda en **Supabase Vault**, no en el código.

### 3. Levantar el banco simulado
Abre el entorno de Mockoon del proyecto e inícialo en el puerto **3000**.

### 4. Ejecutar la app
La URL del banco simulado se define al compilar:

```bash
# Emulador de Android (valor por defecto: http://10.0.2.2:3000)
flutter run

# Teléfono físico en la misma red Wi-Fi que la computadora con Mockoon
flutter run --dart-define=BANK_API_URL=http://<IP-de-tu-PC>:3000

# APK de release
flutter build apk --release --dart-define=BANK_API_URL=http://<IP-de-tu-PC>:3000
```

> [!TIP]
> Si el teléfono no llega a Mockoon, abre `http://<IP-de-tu-PC>:3000/v1/institutions` en su navegador.
> Si no ves el JSON de los bancos, revisa la IP y permite el puerto 3000 en el firewall.

---

## Seguridad y privacidad

- **Row Level Security** en todas las tablas: cada usuario solo puede leer y modificar sus propios datos.
- **Permisos por columna** en `perfiles`: el usuario no puede cambiar, por ejemplo, su documento de identidad.
- Contraseñas gestionadas por Supabase Auth (con hash). La huella la verifica el sistema operativo y nunca sale del dispositivo.
- Tokens bancarios y credenciales para la huella guardados en el **almacenamiento cifrado** del dispositivo.
- Fotos de perfil en un bucket **privado**, servidas con URLs firmadas temporales.
- Eliminación de cuenta mediante una función `security definer` que solo permite borrarse a uno mismo.
- Términos y condiciones redactados conforme a la **Ley 81 de 2019** de protección de datos personales de Panamá.

---

## Estado del proyecto

✅ Versión 1.0 completa, desarrollada como **proyecto académico**.

Posibles mejoras futuras:
- Integración con un agregador bancario real (Open Banking).
- Verificación en dos pasos forzada desde el servidor o con app autenticadora (TOTP).
- Modo oscuro y soporte para iOS.
