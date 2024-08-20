---
{
    .title = "Узагальнені структури даних",
    .date = "2024-08-17T00:00:00",
    .author = "Sonic",
    .draft = false,
    .layout = "learning_zig.shtml",
    .tags = [],
}  
---

У попередній частині ми створили простий динамічний масив під назвою `IntList`. Метою структури даних було зберігати динамічну кількість значень. Хоча використаний нами алгоритм працював би для будь-якого типу даних, наша реалізація була прив’язана до значень `i64`. Введіть генерики, метою яких є абстрагування алгоритмів і структур даних від конкретних типів.

Багато мов реалізують універсали зі спеціальним синтаксисом і специфічними для узагальнених правил. У Zig генерики є не такою специфічною особливістю, як вираженням того, на що здатна мова. Зокрема, дженерики використовують потужне метапрограмування Zig під час компіляції.

Ми почнемо з розгляду дурного прикладу, щоб зорієнтуватися:

<figure>
<figcaption class="zig-cap">learning.zig</figcaption>

```zig
const std = @import("std");

pub fn main() !void {
  var arr: IntArray(3) = undefined;
  arr[0] = 1;
  arr[1] = 10;
  arr[2] = 100;
  std.debug.print("{any}\n", .{arr});
}

fn IntArray(comptime length: usize) type {
  return [length]i64;
}
```

</figure>

Наведене вище друкує `{ 1, 10, 100 }`. Цікава частина полягає в тому, що у нас є функція, яка повертає `тип` (отже, функція PascalCase). Не будь-який тип, а тип, заснований на параметрі функції. Цей код працював лише тому, що ми оголосили `length` як `comptime`. Тобто ми вимагаємо від усіх, хто викликає `IntArray`, передавати відомий під час компіляції параметр `length`. Це необхідно, оскільки наша функція повертає `type`, а `types` завжди мають бути відомі під час компіляції.

Функція може повертати _будь-який_ тип, а не лише примітиви та масиви. Наприклад, з невеликою зміною ми можемо повернути структуру:

<figure>
<figcaption class="zig-cap">learning.zig</figcaption>

```zig
const std = @import("std");

pub fn main() !void {
  var arr: IntArray(3) = undefined;
  arr.items[0] = 1;
  arr.items[1] = 10;
  arr.items[2] = 100;
  std.debug.print("{any}\n", .{arr.items});
}

fn IntArray(comptime length: usize) type {
  return struct {
    items: [length]i64,
  };
}
```

</figure>

Це може здатися дивним, але тип `arr` насправді є `IntArray(3)`. Це такий же тип, як і будь-який інший тип, а `arr` — це значення, як і будь-яке інше значення. Якби ми викликали `IntArray(7)`, це був би інший тип. Можливо, ми зможемо зробити речі акуратнішими:

<figure>
<figcaption class="zig-cap">learning.zig</figcaption>

```zig
const std = @import("std");

pub fn main() !void {
  var arr = IntArray(3).init();
  arr.items[0] = 1;
  arr.items[1] = 10;
  arr.items[2] = 100;
  std.debug.print("{any}\n", .{arr.items});
}

fn IntArray(comptime length: usize) type {
  return struct {
    items: [length]i64,

    fn init() IntArray(length) {
      return .{
        .items = undefined,
      };
    }
  };
}
```

</figure>

На перший погляд це може виглядати не акуратніше. Але крім того, що наша структура безіменна та вкладена у функцію, вона виглядає як будь-яка інша структура, яку ми бачили досі. У нього є поля, у нього є функції. Ви знаєте, як кажуть, _якщо це схоже на качку..._. Ну, це виглядає, плаває і крякає як звичайна структура, тому що це так.

Ми вибрали цей шлях, щоб звикнути до функції, яка повертає тип і відповідний синтаксис. Щоб отримати типовіший дженерик, нам потрібно зробити останню зміну: наша функція має прийняти `type`. Насправді це невелика зміна, але «тип» може здаватися більш абстрактним, ніж «використання», тому ми робили це повільно. Давайте зробимо стрибок і змінимо наш попередній `IntList` для роботи з будь-яким типом. Почнемо зі скелета:

```zig
fn List(comptime T: type) type {
  return struct {
    pos: usize,
    items: []T,
    allocator: Allocator,

    fn init(allocator: Allocator) !List(T) {
      return .{
        .pos = 0,
        .allocator = allocator,
        .items = try allocator.alloc(T, 4),
      };
    }
  };
}
```

Наведена вище `struct` майже ідентична нашому `IntList`, за винятком `i64`, заміненого на `T`. Це `T` може здатися особливим, але це лише назва змінної. Ми могли б назвати це `item_type`. Однак, дотримуючись угоди про іменування Zig, змінні типу `type` є PascalCase.

---

> Добре це чи погано, використання однієї літери для представлення параметра типу набагато старше, ніж Zig. `T` є звичайним за замовчуванням у більшості мов, але ви побачите залежні від контексту варіації, такі як хеш-карти з використанням `K` і `V` для типів параметрів ключа та значення.

---

Якщо ви не впевнені щодо нашого скелета, розгляньте два місця, де ми використовуємо `T`: `items: []T` і `allocator.alloc(T, 4)`. Якщо ми хочемо використовувати цей загальний тип, ми створимо екземпляр за допомогою:

```zig
var list = try List(u32).init(allocator);
```

Коли код компілюється, компілятор створює новий тип, знаходячи кожен `T` і замінюючи його на `u32`. Якщо ми знову використаємо `List(u32)`, компілятор повторно використає тип, який він створив раніше. Якщо ми вкажемо нове значення для "T", наприклад "List(bool)" або "List(User)", буде створено нові типи.

Щоб завершити наш загальний `List`, ми можемо буквально скопіювати та вставити решту коду `IntList` і замінити `i64` на `T`. Ось повний робочий приклад:

<figure>
<figcaption class="zig-cap">learning.zig</figcaption>

```zig
const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
  var gpa = std.heap.GeneralPurposeAllocator(.{}){};
  const allocator = gpa.allocator();

  var list = try List(u32).init(allocator);
  defer list.deinit();

  for (0..10) |i| {
    try list.add(@intCast(i));
  }

  std.debug.print("{any}\n", .{list.items[0..list.pos]});
}

fn List(comptime T: type) type {
  return struct {
    pos: usize,
    items: []T,
    allocator: Allocator,

    fn init(allocator: Allocator) !List(T) {
      return .{
        .pos = 0,
        .allocator = allocator,
        .items = try allocator.alloc(T, 4),
      };
    }

    fn deinit(self: List(T)) void {
      self.allocator.free(self.items);
    }

    fn add(self: *List(T), value: T) !void {
      const pos = self.pos;
      const len = self.items.len;

      if (pos == len) {
        // у нас закінчилось місце
        // створюємо новий, вдвічі більший зріз
        var larger = try self.allocator.alloc(T, len * 2);

        // копіюємо в нього всі елементи з попереднього
        @memcpy(larger[0..len], self.items);

        self.allocator.free(self.items);

        self.items = larger;
      }

      self.items[pos] = value;
      self.pos = pos + 1;
    }
  };
}
```

</figure>

Наша функція `init` повертає `List(T)`, а наші функції `deinit` і `add` приймають `List(T)` і `*List(T)`. У нашому простому класі це добре, але для великих структур даних написання повної загальної назви може стати трохи виснажливим, особливо якщо у нас є кілька параметрів типу (наприклад, хеш-карта, яка приймає окремий «тип» для свого ключа та значення) . Вбудована функція `@This()` повертає внутрішній `type`, звідки вона викликана. Швидше за все, наш `List(T)` буде записаний так:

```zig
fn List(comptime T: type) type {
  return struct {
    pos: usize,
    items: []T,
    allocator: Allocator,

    // додано
    const Self = @This();

    fn init(allocator: Allocator) !Self {
      // ... той самий код
    }

    fn deinit(self: Self) void {
      // .. той самий код
    }

    fn add(self: *Self, value: T) !void {
      // .. той самий код
    }
  };
}
```

`Self` — це не спеціальне ім’я, це просто змінна, і це PascalCase, тому що її значення є `type`. Ми можемо використовувати `Self` там, де раніше використовували `List(T)`.

---

Ми могли б створити складніші приклади з декількома параметрами типу та досконалішими алгоритмами. Але, зрештою, основний загальний код нічим не відрізнятиметься від простих прикладів вище. У наступній частині ми знову торкнемося генериків, коли поглянемо на `ArrayList(T)` і `StringHashMap(V)` стандартної бібліотеки.
