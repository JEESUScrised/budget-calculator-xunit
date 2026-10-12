# Калькулятор бюджета — модульное тестирование (xUnit)

**Студент:** Прилепов Никита Алексеевич  
**Группа:** 4P1.23

Учебный ASP.NET Core Web API для расчёта бюджета поездки и набор unit-тестов на xUnit.

> Готового стартового репозитория в рабочей среде не было. Минимальный API-каркас (модель `BudgetRequest` и `BudgetController`) собран по примеру из задания на .NET 9.

## Что считает приложение

`POST /api/budget/calculate`

- вход: дневная стоимость, число дней, флаг страховки;
- при `Days <= 0` — HTTP 400;
- база: `DailyCost * Days`;
- при страховке итоговая сумма увеличивается на **5%**;
- успех — HTTP 200 и поле `TotalAmount`.

## Ошибка в страховке

В исходном примере стоимость при страховке умножалась на 5 (`total *= 5`), поэтому для `100 × 5` получалось **2500** вместо **525**.

Тест `Calculate_WithInsurance_Returns200And525` упал с:

```text
Expected: 525
Actual:   2500
```

Исправление: `total *= 1.05m`.

## Тесты

| Тест | Ожидание |
|---|---|
| Без страховки (100×5) | 200, 500 |
| Со страховкой (100×5) | 200, 525 |
| Отрицательные дни | 400 |
| Нулевые дни | 400 |
| Нулевая дневная стоимость | 200, 0 |
| Дробная стоимость (100.50×3) | 200, 301.50 |

Фактический прогон после исправления: **6 passed / 0 failed**.

## Покрытие

`dotnet test --collect:"XPlat Code Coverage"`

По Cobertura для `BudgetController`:

- **line coverage: 100%**
- **branch coverage: 100%**

Файл: [reports/coverage.cobertura.xml](reports/coverage.cobertura.xml)

## Как воспроизвести

```powershell
dotnet restore
dotnet build
dotnet test
dotnet test --collect:"XPlat Code Coverage"
```

## Отчёт и скриншоты

- Отчёт: [reports/BudgetCalculator_TestReport.docx](reports/BudgetCalculator_TestReport.docx)
- Скриншоты: [screenshots/](screenshots/)
  - `02_insurance_test_failed.png` — падение теста со страховкой
  - `03_all_tests_passed.png` — все тесты зелёные
  - `04_coverage_summary.png` — сводка покрытия

## Структура

```text
src/BudgetCalculator.Api/     — Web API
tests/BudgetCalculator.Tests/ — xUnit
reports/                      — DOCX + Cobertura
screenshots/                  — доказательства прогонов
```
