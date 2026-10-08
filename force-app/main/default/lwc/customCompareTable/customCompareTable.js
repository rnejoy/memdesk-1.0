import { LightningElement, api, track } from 'lwc';


// Column name of the table
const columns = [
    { label: '', fieldName: 'number', fixedWidth: 50 },
    { label: 'Items', fieldName: 'items' },
    { label: 'Frequency', fieldName: 'frequency', fixedWidth: 150 },
];

export default class CustomCompareTable extends LightningElement {
    @api title;
    @track data = [];
    @track filteredData = [];
    @track searchQuery = '';
    columns = columns;

    _results;

    // To re-render the table when other queries are selected in the dashboard
    @api
    get results() {
        return this._results;
    }

    set results(results) {
        this._results = results;
        if (results) {
            this.frequentlyBrought();
        }
    }

    // Load the data on dashboard start
    connectedCallback() {
        this.frequentlyBrought();
    }

    // Compares and counts the frequency of items bought together
    frequentlyBrought() {
        const data = this.results;

        // Step 1: Group items by transaction number
        const groupedData = data.reduce((acc, item) => {
            const transactionNo = item["J0A.transactionno"];
            acc[transactionNo] = acc[transactionNo] || [];
            acc[transactionNo].push(item["J0A.J2.articledescription"]);
            return acc;
        }, {});

        // Step 2: Count co-occurrences of articledescription within each transactionno
        const coOccurrenceMap = {};

        for (const transactionNo in groupedData) {
            const items = groupedData[transactionNo];
            for (let i = 0; i < items.length; i++) {
                for (let j = i + 1; j < items.length; j++) {
                    const pair = [items[i], items[j]].sort().join(" & "); // Ensure pairs are unique
                    coOccurrenceMap[pair] = (coOccurrenceMap[pair] || 0) + 1;
                }
            }
        }

        // Step 3: Sort co-occurrences by frequency and map for template iteration
        this.data = Object.entries(coOccurrenceMap)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 101)
            .map(([items, frequency], index) => ({
                key: `row-${index}`,
                items,
                frequency,
            }));

        this.filterData();
    }

    // Handles search bar
    handleSearchChange(event) {
        this.searchQuery = event.target.value.toLowerCase();
        this.filterData();
    }

    filterData() {
        if (!this.searchQuery) {
            this.filteredData = [...this.data];
            return;
        }

        this.filteredData = this.data.filter(({ items }) => 
            items.toLowerCase().includes(this.searchQuery)
        );
    }
}