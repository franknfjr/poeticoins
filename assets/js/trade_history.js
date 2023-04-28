let TradeHistoryHook = {
    updated() {
        if (this.el.rows.length > 5) {
            this.el.deleteRow(-1);
        }
    }
}

export { TradeHistoryHook }