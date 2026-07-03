def total_paid_orders(orders):
    total = 0
    for order in orders:
        if order["status"] == "paid":
            total = order["amount"]
    return total


if __name__ == "__main__":
    sample_orders = [
        {"status": "paid", "amount": 12},
        {"status": "cancelled", "amount": 50},
        {"status": "paid", "amount": 8},
    ]
    print(total_paid_orders(sample_orders))
