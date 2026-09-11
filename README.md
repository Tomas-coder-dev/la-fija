# La Fija 💳

Web App en Flutter para controlar gastos de tarjetas de crédito por ciclos de facturación. Backend 100% en [Supabase](https://supabase.com).

## ✨ Funcionalidades

- 🔐 Autenticación con Google OAuth (vía Supabase)
- 📊 Dashboard con progreso visual de cada tarjeta (meta mensual vs. consumo real)
- 🗓️ Motor de ciclo de facturación inteligente basado en el `dia_cierre` de cada tarjeta
- ➕ Registro rápido de gastos con modal (FAB)
- 🎨 Diseño Material 3, tema oscuro, colores índigo

## 🛠️ Stack

| Capa | Tecnología |
|---|---|
| Framework | Flutter (Web) |
| Backend / DB | Supabase (PostgreSQL) |
| Auth | Supabase + Google OAuth |
| UI | Material 3, google_fonts, percent_indicator |
| Moneda | intl (formato S/ peruano) |

## 📁 Estructura

```
lib/
├── main.dart                    # Entry point + AuthGate
├── models/
│   ├── credit_card.dart         # Modelo → tabla `tarjetas`
│   └── expense.dart             # Modelo → tabla `gastos`
├── services/
│   └── supabase_service.dart    # CRUD + lógica de ciclo de facturación
├── screens/
│   ├── login_screen.dart        # Pantalla de login con Google
│   └── dashboard_screen.dart    # Dashboard principal
└── widgets/
    └── card_progress_widget.dart # Widget de progreso por tarjeta
```

## 🚀 Setup

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU_USUARIO/la-fija.git
cd la-fija
```

### 2. Configurar credenciales de Supabase

Edita `lib/main.dart` y reemplaza las credenciales:

```dart
await Supabase.initialize(
  url: 'TU_SUPABASE_URL',
  anonKey: 'TU_SUPABASE_ANON_KEY',
);
```

> ⚠️ **Nunca subas credenciales reales al repositorio.**

### 3. Crear tablas en Supabase

```sql
CREATE TABLE tarjetas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  banco TEXT NOT NULL,
  nombre_tarjeta TEXT NOT NULL,
  dia_cierre INTEGER NOT NULL CHECK (dia_cierre BETWEEN 1 AND 31),
  dia_pago INTEGER NOT NULL CHECK (dia_pago BETWEEN 1 AND 31),
  meta_mensual NUMERIC(10, 2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gastos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tarjeta_id UUID REFERENCES tarjetas(id) ON DELETE CASCADE NOT NULL,
  monto NUMERIC(10, 2) NOT NULL CHECK (monto > 0),
  fecha_consumo TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE tarjetas ENABLE ROW LEVEL SECURITY;
ALTER TABLE gastos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cards" ON tarjetas FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own cards" ON tarjetas FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own expenses" ON gastos FOR SELECT USING (tarjeta_id IN (SELECT id FROM tarjetas WHERE user_id = auth.uid()));
CREATE POLICY "Users can insert own expenses" ON gastos FOR INSERT WITH CHECK (tarjeta_id IN (SELECT id FROM tarjetas WHERE user_id = auth.uid()));
```

### 4. Ejecutar

```bash
flutter pub get
flutter run -d chrome
```

## 📦 Build de producción

```bash
flutter build web --release
```
