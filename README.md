# simple-cpu-cache

Пример реализации процессорного кеша 1-го уровня.

## Зависимости

Для запуска и тестирования необходимо использовать

* **iverilog** (`brew install icarus-verilog`)
* **GtkWave** (`brew cask install xquartz && brew cask install gtkwave`)

## Запуск

Компиляция:

```bash
iverilog memory_of_tags.v memory_of_tags_testfixture.v && vvp ./a.out
```

Временная диаграмма:

```bash
gtkwave ./dump.vcd
```
