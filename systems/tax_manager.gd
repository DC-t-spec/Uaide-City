extends Node

# ============================================================
# UAIDE CITY - TAX MANAGER
# Sistema central de impostos
# ============================================================

signal tax_collected(tax_data: Dictionary)

const SALARY_TAX_RATE := 0.05
const PROPERTY_PURCHASE_TAX_RATE := 0.03
const VAT_RATE := 0.05
const MONTHLY_PROPERTY_TAX := 10


func calculate_salary_tax(gross_amount: int) -> int:
	if gross_amount <= 0:
		return 0

	return int(round(gross_amount * SALARY_TAX_RATE))


func calculate_property_purchase_tax(price: int) -> int:
	if price <= 0:
		return 0

	return int(round(price * PROPERTY_PURCHASE_TAX_RATE))


func calculate_vat(base_amount: int) -> int:
	if base_amount <= 0:
		return 0

	return int(round(base_amount * VAT_RATE))


func get_total_with_vat(base_amount: int) -> int:
	return base_amount + calculate_vat(base_amount)


func get_monthly_property_tax() -> int:
	return MONTHLY_PROPERTY_TAX


func register_salary_tax(tax_amount: int, job_id: String = "") -> void:
	if tax_amount <= 0:
		return

	FinanceManager.register_expense(
		"tax_salary",
		tax_amount,
		"Imposto sobre salário",
		"tax",
		job_id
	)

	_emit_tax("salary", tax_amount, job_id)


func register_property_purchase_tax(tax_amount: int, property_id: String) -> void:
	if tax_amount <= 0:
		return

	FinanceManager.register_expense(
		"tax_property_purchase",
		tax_amount,
		"Imposto sobre compra de propriedade",
		"tax",
		property_id
	)

	_emit_tax("property_purchase", tax_amount, property_id)


func register_vat(tax_amount: int, reference_id: String = "") -> void:
	if tax_amount <= 0:
		return

	FinanceManager.register_expense(
		"tax_vat",
		tax_amount,
		"IVA sobre produto/serviço",
		"tax",
		reference_id
	)

	_emit_tax("vat", tax_amount, reference_id)


func charge_monthly_property_tax(property_data: Dictionary) -> bool:
	if property_data.is_empty():
		return false

	var property_id: String = str(property_data.get("id", ""))
	var property_name: String = str(property_data.get("name", "Propriedade"))

	if property_id == "":
		return false

	var tax_amount: int = MONTHLY_PROPERTY_TAX

	var paid: bool = ExpenseManager.charge_expense(
		"tax_property_monthly",
		tax_amount,
		"Imposto mensal de propriedade - %s" % property_name,
		"tax",
		property_id
	)

	if paid:
		_emit_tax("property_monthly", tax_amount, property_id)
		print("Imposto mensal de propriedade cobrado:", property_name, "-", tax_amount, "MZN")
	else:
		print("Imposto mensal de propriedade ficou pendente:", property_name, "-", tax_amount, "MZN")

	return paid


func _emit_tax(tax_type: String, amount: int, reference_id: String) -> void:
	var tax_data := {
		"type": tax_type,
		"amount": amount,
		"reference_id": reference_id,
		"day": TimeManager.get_current_day_absolute()
	}

	tax_collected.emit(tax_data)
