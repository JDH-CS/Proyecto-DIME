/// Texto de los Términos y Condiciones y Política de Privacidad de DIME.
///
/// Si se cambia el contenido de forma sustancial, sube [version]: la versión
/// aceptada se guarda en los metadatos del usuario al registrarse.
class TermsText {
  TermsText._();

  static const version = '1.0';
  static const vigencia = '23 de noviembre de 2026';

  static const aviso =
      'Conexión bancaria simulada. En esta versión de DIME la vinculación con bancos es una '
      'demostración: no se conecta con ninguna institución financiera real y todos los saldos, '
      'cuentas y movimientos bancarios que muestra son ficticios. Nunca te pediremos el usuario '
      'ni la contraseña de tu banca en línea.';

  /// (título, párrafos). Un párrafo que empieza con "• " se muestra como viñeta.
  static const List<(String, List<String>)> secciones = [
    ('1. Aceptación de los términos', [
      'Estos Términos y Condiciones y la Política de Privacidad incluida en ellos (en conjunto, los '
          '"Términos") regulan el uso de la aplicación móvil DIME (la "Aplicación" o el "Servicio").',
      'Al marcar la casilla "He leído y aceptado los términos y condiciones" y crear tu cuenta, '
          'aceptas estos Términos por medios electrónicos, con la misma validez que una firma '
          'manuscrita, conforme a la Ley 51 de 2008 sobre documentos y firmas electrónicas de la '
          'República de Panamá. Si no estás de acuerdo, no crees una cuenta ni uses la Aplicación.',
    ]),
    ('2. Qué es DIME y qué no es', [
      'DIME es una herramienta de presupuesto personal basada en el método de asignación de cada '
          'dólar: te permite registrar ingresos y gastos, asignar dinero a categorías, ver gráficas '
          'y generar informes de tus finanzas.',
      '• DIME no es un banco, cooperativa, casa de valores, empresa financiera ni asesor de '
          'inversiones, y no está supervisado por la Superintendencia de Bancos de Panamá.',
      '• DIME no recibe, custodia ni transfiere dinero, y no puede realizar pagos ni movimientos '
          'en tus cuentas bancarias.',
      '• Los nombres y logotipos de bancos que aparecen en la Aplicación se usan solo con fines '
          'ilustrativos. DIME no tiene afiliación, patrocinio ni acuerdo con esas instituciones.',
    ]),
    ('3. Requisitos para usar DIME', [
      '• Ser mayor de 18 años y tener capacidad legal para contratar.',
      '• Proporcionar información verdadera, completa y actualizada, incluido un documento de '
          'identidad (cédula o pasaporte) que te pertenezca.',
      '• Tener una sola cuenta por persona y no crear cuentas a nombre de terceros.',
    ]),
    ('4. Tu cuenta y su seguridad', [
      'Eres responsable de mantener la confidencialidad de tu contraseña y de toda actividad '
          'realizada con tu cuenta. Para protegerla, DIME ofrece:',
      '• Verificación de tu correo electrónico al registrarte.',
      '• Verificación en dos pasos opcional: un código enviado a tu correo cada vez que inicias sesión.',
      '• Inicio de sesión con huella o rostro: la verificación biométrica la realiza el sistema '
          'operativo de tu teléfono. DIME nunca recibe ni almacena tu huella o tu rostro.',
      'Si sospechas que alguien accedió a tu cuenta sin autorización, cambia tu contraseña y '
          'escríbenos de inmediato desde "Ayuda y soporte".',
    ]),
    ('5. Conexión bancaria (Open Banking)', [
      'Importante: en la versión actual, la conexión bancaria es simulada. La Aplicación se '
          'comunica con un servidor de pruebas que imita el funcionamiento de un banco; no se '
          'conecta con ninguna institución financiera real y los datos bancarios que muestra son '
          'ficticios.',
      'Cuando la conexión con bancos reales esté disponible, funcionará así, y te lo notificaremos '
          'antes de activarla:',
      '• Autorizarás el acceso directamente en el sitio de tu banco mediante el estándar OAuth 2.0. '
          'DIME nunca verá ni guardará tu usuario o contraseña bancaria.',
      '• El acceso será de solo lectura: saldos, cuentas y movimientos. DIME no podrá mover dinero.',
      '• Los permisos de acceso (tokens) se guardarán cifrados en tu dispositivo y podrás revocarlos '
          'en cualquier momento desde "Administrar cuenta bancaria" o desde tu banco.',
    ]),
    ('6. Datos personales que recopilamos', [
      '• Identificación: nombre, apellido, fecha de nacimiento y número de cédula o pasaporte.',
      '• Contacto: correo electrónico y número de celular.',
      '• Información financiera que tú ingresas: presupuestos, categorías, asignaciones y '
          'transacciones manuales.',
      '• Información de la conexión bancaria simulada: cuentas y movimientos ficticios.',
      '• Foto de perfil, si decides subirla, y los reportes que envíes a soporte.',
      '• Preferencias de la Aplicación (por ejemplo, el modo de accesibilidad), que se guardan '
          'solo en tu dispositivo.',
      'No recopilamos tu ubicación, tus contactos ni tus datos biométricos, y no rastreamos tu '
          'actividad en otras aplicaciones.',
    ]),
    ('7. Para qué usamos tus datos', [
      'Tratamos tus datos personales con tu consentimiento y para cumplir la relación que '
          'establecemos contigo, conforme a la Ley 81 de 2019 sobre Protección de Datos Personales '
          'de Panamá y su reglamento, con estas finalidades:',
      '• Crear y administrar tu cuenta y verificar tu identidad al iniciar sesión.',
      '• Prestarte el Servicio: presupuesto, categorización de transacciones, gráficas e informes.',
      '• Atender tus solicitudes de soporte.',
      '• Proteger la seguridad de la Aplicación y prevenir fraudes o usos indebidos.',
      '• Cumplir obligaciones legales.',
      'No vendemos, alquilamos ni compartimos tus datos con fines publicitarios.',
    ]),
    ('8. Cómo protegemos tu información', [
      '• Cifrado en tránsito: la comunicación entre la Aplicación y nuestros servidores viaja '
          'cifrada mediante HTTPS/TLS.',
      '• Contraseñas: se almacenan transformadas con un algoritmo de hash; nadie en DIME puede '
          'conocer tu contraseña.',
      '• Aislamiento de datos: la base de datos aplica seguridad a nivel de fila, de modo que cada '
          'usuario solo puede leer y modificar su propia información.',
      '• En tu dispositivo: las credenciales para el inicio con huella y los permisos bancarios se '
          'guardan en el almacenamiento cifrado del sistema (Android Keystore o iOS Keychain).',
      '• Archivos: las fotos de perfil se guardan en un almacenamiento privado y solo se muestran '
          'mediante enlaces temporales.',
      'Ningún sistema es completamente infalible. Si ocurriera un incidente de seguridad que '
          'afecte tus datos, te lo notificaremos y actuaremos conforme a la normativa vigente.',
    ]),
    ('9. Con quién compartimos tus datos', [
      'Solo con proveedores que nos ayudan a prestar el Servicio y que actúan siguiendo nuestras '
          'instrucciones:',
      '• Supabase: alojamiento de la base de datos, autenticación y almacenamiento de archivos.',
      '• Brevo: envío de correos transaccionales (códigos de verificación y recuperación).',
      'Estos proveedores pueden tener servidores fuera de Panamá. En ese caso, la transferencia '
          'se realiza con medidas de protección equivalentes a las exigidas por la ley panameña.',
      'También podremos revelar datos cuando lo ordene una autoridad competente conforme a la ley.',
    ]),
    ('10. Conservación de los datos', [
      'Conservamos tus datos mientras tu cuenta esté activa. Puedes eliminar tu cuenta tú mismo en '
          'cualquier momento desde "Administrar cuenta de DIME" > "Eliminar mi cuenta": se borran '
          'de inmediato tu perfil, categorías, presupuestos, transacciones, conexión bancaria y foto, '
          'y recibirás un correo de confirmación. Solo guardamos, de forma anónima, el motivo de baja '
          'que elijas. Las cuentas que nunca confirmaron su correo pueden ser eliminadas para liberar el documento de identidad registrado.',
    ]),
    ('11. Tus derechos', [
      'Conforme a la Ley 81 de 2019, puedes ejercer en cualquier momento tus derechos de:',
      '• Acceso: saber qué datos tuyos tratamos.',
      '• Rectificación: corregir datos inexactos o incompletos (muchos puedes editarlos tú mismo '
          'en "Administrar perfil").',
      '• Cancelación: eliminar tus datos y tu cuenta, directamente desde la Aplicación.',
      '• Oposición: oponerte a un tratamiento determinado.',
      '• Portabilidad: recibir tus datos en un formato estructurado. El informe financiero en PDF '
          'te permite descargar tu información en cualquier momento.',
      'Para ejercerlos, escríbenos desde "Ayuda y soporte" o "Administrar cuenta de DIME". '
          'Responderemos dentro de los plazos que establece la normativa. Si no estás conforme con '
          'nuestra respuesta, puedes acudir a la Autoridad Nacional de Transparencia y Acceso a la '
          'Información (ANTAI). También puedes retirar tu consentimiento, lo que implicará cerrar '
          'tu cuenta.',
    ]),
    ('12. Uso aceptable', [
      'Te comprometes a no:',
      '• Usar DIME para actividades ilícitas, incluido el lavado de dinero o el fraude.',
      '• Intentar acceder a cuentas o datos de otros usuarios, o vulnerar la seguridad del Servicio.',
      '• Copiar, descompilar o aplicar ingeniería inversa a la Aplicación, salvo lo permitido por la ley.',
      '• Usar programas automatizados para acceder al Servicio.',
    ]),
    ('13. La información de DIME no es asesoría financiera', [
      'Los saldos, el patrimonio neto, las gráficas, las recomendaciones y los informes que genera '
          'DIME son estimaciones informativas calculadas con los datos registrados. No constituyen '
          'asesoría financiera, contable, tributaria ni de inversión. Las decisiones que tomes con '
          'base en ellos son tu responsabilidad.',
    ]),
    ('14. Disponibilidad y responsabilidad', [
      'Trabajamos para que DIME esté disponible y funcione correctamente, pero el Servicio se '
          'ofrece "tal cual" y puede tener interrupciones por mantenimiento o causas ajenas a '
          'nosotros.',
      'En la medida permitida por la ley, DIME no será responsable por pérdidas derivadas de '
          'decisiones financieras tomadas con base en la Aplicación, de datos incorrectos ingresados '
          'por el usuario o del uso indebido de su cuenta por no proteger sus credenciales. Nada en '
          'estos Términos limita los derechos que te reconoce la Ley 45 de 2007 de protección al '
          'consumidor.',
    ]),
    ('15. Propiedad intelectual', [
      'La marca DIME, su logotipo, diseño y código son propiedad de sus desarrolladores. Te '
          'otorgamos una licencia personal, limitada, no exclusiva e intransferible para usar la '
          'Aplicación. Tus datos siguen siendo tuyos.',
    ]),
    ('16. Suspensión y cierre de la cuenta', [
      'Puedes dejar de usar DIME y eliminar tu cuenta cuando quieras desde la Aplicación. Podremos '
          'suspender o cerrar cuentas que incumplan estos Términos, avisándote cuando sea posible.',
    ]),
    ('17. Cambios a estos Términos', [
      'Podremos actualizar estos Términos. Te avisaremos dentro de la Aplicación indicando la '
          'nueva versión y su fecha de vigencia. Si los cambios son sustanciales, te pediremos que '
          'los aceptes de nuevo antes de seguir usando el Servicio.',
    ]),
    ('18. Ley aplicable', [
      'Estos Términos se rigen por las leyes de la República de Panamá. Cualquier controversia se '
          'intentará resolver primero de forma amistosa; de no lograrse, se someterá a los '
          'tribunales competentes de la ciudad de Panamá.',
    ]),
    ('19. Contacto', [
      'Para preguntas sobre estos Términos o sobre tus datos personales, usa la opción "Enviar un '
          'reporte" en "Ayuda y soporte" dentro de la Aplicación.',
    ]),
  ];
}
