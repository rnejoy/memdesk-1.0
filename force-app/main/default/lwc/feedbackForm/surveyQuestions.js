/**
 * surveyQuestions.js
 * Single source of truth for the Landers Exit Survey question flow.
 * Rebuilt against "FINAL_Revised_Exit_Survey_Questions.xlsx".
 *
 * Question "type" values the engine understands:
 *   single-select          - one choice from options[]
 *   single-select-dynamic  - one choice, options built at runtime from
 *                             another question's answer (see optionsSource)
 *   multi-select           - many choices from options[], optional maxItems,
 *                             optional allowOther
 *   open-text              - one free-text answer
 *   open-text-multi        - up to maxItems separate free-text answers
 *   star-matrix            - 1-5 star rating per row in rows[]
 *   satisfaction-followup  - special virtual question: asks a short
 *                             open-text follow-up for the (up to 2) lowest
 *                             scoring rows from the star-matrix question
 *   nps-scale              - 0-10 scale
 *   yes-no                 - Yes/No, stored as the string 'Yes' / 'No'
 *   checkbox                - boolean opt-in (used for the consent question)
 *
 * Every question carries a `category` matching the "Category" column of
 * FINAL_Revised_Exit_Survey_Questions.xlsx. Follow-up questions that share
 * a row with their parent in the sheet (e.g. Availability_Open_Text__c,
 * the NPS branch questions, the Renewal branch questions) inherit that
 * same category string - this is what feedbackForm.js uses to compute the
 * "Category X of Y" progress indicator, counting only categories that are
 * actually reachable given the answers so far.
 *
 * showIf conditions (evaluated against previously-collected answers):
 *   { question: 'Q9_NPS', scoreBetween: [9, 10] }
 *   { question: 'Q10_RENEWAL', in: ['X', 'Y'] }
 *   { question: 'Q9C_CONSENT', equals: true }
 *   { custom: 'hasLowSatisfactionScore' }   - see CUSTOM_CONDITIONS below,
 *                                              for conditions that depend on
 *                                              more than one prior answer
 */

export const OTHER_OPTION = 'Other (please specify)';

// The literal text of the "opt out of everywhere" choice in Q6_WALLET.
// Referenced by the CUSTOM_CONDITIONS below and by the dynamic-options
// logic for Q6A_WALLET_TOP.
export const NONE_WALLET_OPTION = 'None - Landers is where I do all my grocery';

// Rows for the Q4_SATISFACTION star-rating matrix. Keys are used internally
// (answers.Q4_SATISFACTION[key] = 1-5); `field` is the Salesforce API name
// each row maps to on Member_Feedback__c.
export const SATISFACTION_ROWS = [
    { key: 'appearance', field: 'Rate_Store_Appearance__c', label: 'Store appearance and cleanliness' },
    { key: 'fresh', field: 'Rate_Fresh_Items__c', label: 'Freshness and quality of fresh items' },
    { key: 'availability', field: 'Rate_Product_Availability__c', label: 'Variety and choice of products' },
    { key: 'value', field: 'Rate_Value_For_Money__c', label: 'Value for money' },
    { key: 'checkout', field: 'Rate_Checkout_Experience__c', label: 'Speed and friendliness at checkout' },
    { key: 'food', field: 'Rate_Food_Choices__c', label: 'Food choices - food court, bakery, ready-to-eat' }
];

/**
 * Returns up to the 2 lowest-scoring satisfaction rows that scored 3 or
 * below (i.e. "needs work"), sorted worst-first. Used to decide whether to
 * show the Q4_FOLLOWUP question, and which rows to ask about.
 */
export function getLowSatisfactionRows(answers) {
    const scores = answers.Q4_SATISFACTION || {};
    return SATISFACTION_ROWS.map((r) => ({ ...r, score: scores[r.key] }))
        .filter((r) => typeof r.score === 'number' && r.score > 0 && r.score <= 3)
        .sort((a, b) => a.score - b.score)
        .slice(0, 2);
}

// Named predicates for showIf conditions that need to look at more than one
// prior answer (a plain `question` / `equals` / `in` pair can't express
// these). Referenced from a question via showIf: { custom: 'name' }.
export const CUSTOM_CONDITIONS = {
    hasLowSatisfactionScore: (answers) => getLowSatisfactionRows(answers).length > 0,

    // Q6A_WALLET_TOP only makes sense if they picked at least one store
    // besides "None - Landers is where I do all my grocery".
    walletHasOtherStores: (answers) => {
        const selected = answers.Q6_WALLET || [];
        return selected.some((v) => v !== NONE_WALLET_OPTION);
    },

    // Q6B_WALLET_BETTER only makes sense if some *other* store is getting
    // the biggest share of wallet - if they said Landers, there's nothing
    // else to ask "what does that store do better".
    walletTopIsNotLanders: (answers) =>
        !!answers.Q6A_WALLET_TOP && answers.Q6A_WALLET_TOP !== 'Landers'
};

export const SECTIONS = [
    {
        id: 'A',
        title: 'Your visit today',
        questions: [
            {
                id: 'Q1_TRIP',
                type: 'single-select',
                category: 'Trip Mission',
                field: 'Trip_Mission__c',
                text: 'First, what brought you to Landers today?',
                options: [
                    'Regular grocery run',
                    'Big stock-up for the household',
                    'Quick top-up for a few items',
                    'Mainly for fresh - produce, meat, seafood',
                    'Mainly for the food court or bakery',
                    'Buying for a business or for resale',
                    'First time trying to shop at Landers',
                    'Just browsing or checking promos'
                ]
            },
            {
                id: 'Q2_AVAILABILITY',
                type: 'single-select',
                category: 'Assortment / Availability',
                field: 'Availability__c',
                text: 'Were you able to find everything you came for today?',
                options: ['Yes, everything', 'Most of it', 'No, I missed a few things']
            },
            {
                id: 'Q2A_AVAILABILITY_ITEMS',
                type: 'open-text-multi',
                category: 'Assortment / Availability',
                maxItems: 3,
                maxItemsArray: [0, 1, 2],
                field: 'Availability_Open_Text__c',
                required: true,
                text: 'Which item or items were you looking for?',
                showIf: { question: 'Q2_AVAILABILITY', in: ['Most of it', 'No, I missed a few things'] }
            },
            {
                id: 'Q2B_AVAILABILITY_FOLLOWUP',
                type: 'multi-select',
                category: 'Assortment / Availability',
                allowOther: true,
                field: 'Availability_Follow_Up__c',
                text: 'What happened with that item?',
                showIf: { question: 'Q2_AVAILABILITY', in: ['Most of it', 'No, I missed a few things'] },
                options: [
                    'It was out of stock',
                    "You don't carry it",
                    "I couldn't find it in the store",
                    'Only a bigger or smaller size was available',
                    'The price was higher than I expected'
                ]
            },
            {
                id: 'Q3_CHECKOUT',
                type: 'single-select',
                category: 'Checkout',
                field: 'Checkout__c',
                text: 'How was checkout today - roughly how long did you wait in line?',
                options: ['Under 5 minutes', '5-10 minutes', '10-15 minutes', 'More than 15 minutes']
            }
        ]
    },
    {
        id: 'B',
        title: 'How we are doing',
        questions: [
            {
                id: 'Q4_SATISFACTION',
                type: 'star-matrix',
                category: 'Satisfaction',
                text: 'How would you rate us today on each of these? 1 star = needs work, 5 stars = excellent.',
                rows: SATISFACTION_ROWS
            },
            {
                id: 'Q4_FOLLOWUP',
                type: 'satisfaction-followup',
                category: 'Satisfaction',
                field: 'Satisfaction_Follow_Up__c',
                required: true,
                text: 'A couple of quick follow-ups on that.',
                showIf: { custom: 'hasLowSatisfactionScore' }
            }
        ]
    },
    {
        id: 'C',
        title: 'Fresh & competition',
        questions: [
            {
                id: 'Q5_FRESH',
                type: 'single-select',
                category: 'Fresh / Competitive',
                field: 'Fresh_Section__c',
                text: 'Compared with other stores you shop at, how do our fresh items - produce, meat and seafood - stack up?',
                options: ["Best I've tried", 'Better than most', 'About the same', 'Could be better', "I don't buy fresh here"]
            },
            {
                id: 'Q5A_FRESH_FOLLOWUP',
                type: 'multi-select',
                category: 'Fresh / Competitive',
                allowOther: true,
                field: 'Fresh_Section_Follow_Up__c',
                text: 'What would make our fresh section better for you?',
                showIf: { question: 'Q5_FRESH', in: ["Best I've tried", 'Better than most', 'About the same', 'Could be better'] },
                options: [
                    'Freshness on the shelf',
                    'Price',
                    'Variety',
                    'Packaging or portion sizes',
                    'Still being well-stocked later in the day'
                ]
            },
            {
                id: 'Q6_WALLET',
                type: 'multi-select',
                category: 'Competitive / Share of wallet',
                field: 'Share_Of_Wallet__c',
                text: 'Where else does your household usually do grocery?',
                options: [
                    'S&R',
                    'SM Supermarket / Savemore (SMAC)',
                    'Robinsons Supermarket (GoRewards)',
                    'Puregold (Perks/TNAP)',
                    'Waltermart',
                    'Shopwise',
                    'Public Market',
                    'Neighbourhood sari-sari store',
                    'Online - Lazada,Shopee,GrabMart,MetroMart',
                    NONE_WALLET_OPTION
                ]
            },
            {
                id: 'Q6A_WALLET_TOP',
                type: 'single-select-dynamic',
                category: 'Competitive / Share of wallet',
                field: 'Share_Of_Wallet_a__c',
                text: 'Of all of those, which one gets the biggest share of your grocery budget?',
                // Options = whatever they picked in Q6_WALLET (minus the
                // "none" option), with Landers always added to the list.
                optionsSource: 'Q6_WALLET',
                alwaysInclude: ['Landers'],
                showIf: { custom: 'walletHasOtherStores' }
            },
            {
                id: 'Q6B_WALLET_BETTER',
                type: 'multi-select',
                category: 'Competitive / Share of wallet',
                maxItems: 3,
                allowOther: true,
                field: 'Share_Of_Wallet_b__c',
                text: 'What does that store do better for your household?',
                showIf: { custom: 'walletTopIsNotLanders' },
                options: [
                    'Lower prices',
                    'Closer to home or work',
                    'Wider range of products',
                    'Better fresh section',
                    'Better promos and discounts',
                    'Faster checkout',
                    'Better for small or quick trips',
                    'Delivery available'
                ]
            },
            {
                id: 'Q7_LEAKAGE',
                type: 'yes-no',
                category: 'Leakage',
                field: 'Leakage__c',
                text: 'In the last 3 months, was there something you planned to buy at Landers but ended up buying somewhere else?'
            },
            {
                id: 'Q7A_LEAKAGE_FOLLOWUP',
                type: 'single-select',
                category: 'Leakage',
                allowOther: true,
                field: 'Leakage__Follow_Up__c',
                text: 'What was it, where did you buy it, and what made you buy it there?',
                showIf: { question: 'Q7_LEAKAGE', equals: 'Yes' },
                options: [
                    'It was out of stock here',
                    'It was cheaper there',
                    "You don't carry that brand or size",
                    'It was more convenient at the time',
                    'I saw a promo there'
                ]
            }
        ]
    },
    {
        id: 'D',
        title: 'Value and loyalty',
        questions: [
            {
                id: 'Q8_PRICING',
                type: 'multi-select',
                category: 'Pricing',
                field: 'Pricing__c',
                maxItems: 2,
                allowOther: true,
                text: 'What would keep you shopping with us?',
                options: [
                    'Same price vs other grocery stores',
                    'Better member-only deals',
                    'Bulk or value-pack savings',
                    'Faster checkout',
                    'Better fresh quality',
                    'Wider selection',
                    'Honestly, price is what matters most to me'
                ]
            },
            {
                id: 'Q9_NPS',
                type: 'nps-scale',
                category: 'NPS (retained)',
                field: 'Rate_Recommendation__c',
                text: 'On a scale of 1 to 10, how likely are you to recommend a Landers membership to a friend or family member?'
            },
            {
                id: 'Q9A_PROMOTERS',
                type: 'multi-select',
                category: 'NPS - Promoters (9-10)',
                maxItems: 2,
                allowOther: true,
                field: 'Rate_Recommendation__Promoters__c',
                text: 'What do you love most about shopping here?',
                showIf: { question: 'Q9_NPS', scoreBetween: [9, 10] },
                options: [
                    'Prices and value',
                    'Product quality',
                    "Products I can't find elsewhere",
                    'Food court and bakery',
                    'The shopping experience and store feel',
                    'Staff service',
                    'Member perks and promos'
                ]
            },
            {
                id: 'Q9B_PASSIVE',
                type: 'open-text',
                category: 'NPS - Passives (7-8)',
                field: 'Rate_Recommendation_Passive__c',
                text: 'What one thing would have made that a 10?',
                showIf: { question: 'Q9_NPS', scoreBetween: [7, 8] }
            },
            {
                id: 'Q9C_DETRACTORS',
                type: 'multi-select',
                category: 'NPS - Detractors (1-6)',
                allowOther: true,
                field: 'Rate_Recommendation_Detractors__c',
                text: "Thank you for being honest - we'd rather know. What mattered most in that score?",
                showIf: { question: 'Q9_NPS', scoreBetween: [1, 6] },
                options: [
                    'Prices',
                    'Product availability',
                    'Product quality',
                    'Checkout wait',
                    'Store condition',
                    'Staff service',
                    'Membership fee versus the benefit',
                    'Food choices'
                ]
            },
            {
                id: 'Q9C_CONSENT',
                type: 'checkbox',
                category: 'NPS - Detractors (1-6)',
                field: 'Service_Recovery_Consent__c',
                text: 'May our store manager give you a call to make it right?',
                required: true,
                showIf: { question: 'Q9_NPS', scoreBetween: [1, 6] }
            },
            {
                id: 'Q9C_PHONE',
                type: 'open-text',
                category: 'NPS - Detractors (1-6)',
                field: 'Service_Recovery_Phone__c',
                text: 'What number can they reach you at?',
                showIf: { question: 'Q9C_CONSENT', equals: true }
            },
            {
                id: 'Q10_RENEWAL',
                type: 'single-select',
                category: 'Renewal',
                field: 'Renewal__c',
                text: 'When your membership comes up for renewal, do you see yourself renewing?',
                options: ['Definitely will', 'Probably will', 'Not sure yet', "Probably won't", "Definitely won't"]
            },
            {
                id: 'Q10A_LIKELY',
                type: 'multi-select',
                category: 'Renewal - likely',
                maxItems: 3,
                field: 'Renewal_Comments_1__c',
                text: 'What makes it worth renewing for you?',
                showIf: { question: 'Q10_RENEWAL', in: ['Definitely will', 'Probably will'] },
                options: [
                    'Competitive prices',
                    'Product quality',
                    'Landers own-brand products',
                    "Products I can't get elsewhere",
                    'The shopping experience',
                    'Food court and bakery',
                    'Fuel or other member benefits',
                    "Habit - it's simply our regular store"
                ]
            },
            {
                id: 'Q10B_ATRISK',
                type: 'multi-select',
                category: 'Renewal - at risk',
                allowOther: true,
                field: 'Renewal_Comments_2__c',
                text: "What's holding you back?",
                showIf: { question: 'Q10_RENEWAL', in: ['Not sure yet', "Probably won't", "Definitely won't"] },
                options: [
                    'The fee versus how much I actually save',
                    "I don't visit often enough to justify it",
                    'Prices are no longer as competitive',
                    'The store is far from us',
                    'Stock availability',
                    'Another store fits us better now',
                    'Service experience'
                ]
            },
            {
                id: 'Q10B_CLOSING',
                type: 'single-select',
                category: 'Renewal - at risk',
                field: 'Renewal_Comments_2_Closing__c',
                text: 'If we could sort that out, would you reconsider?',
                showIf: { question: 'Q10_RENEWAL', in: ['Not sure yet', "Probably won't", "Definitely won't"] },
                options: ['Yes', 'Maybe', 'No']
            }
        ]
    },
    {
        id: 'E',
        title: 'Keeping in touch',
        questions: [
            {
                id: 'Q11_CAMPAIGN',
                type: 'multi-select',
                category: 'Campaign reach',
                field: 'Campaign_Reach__c',
                text: 'How would you like us to keep you posted on member deals?',
                options: ['SMS', 'Email', 'Viber', 'Facebook', 'Landers app', 'In-store signage', 'Just tell me at the counter']
            }
        ]
    },
    {
        id: 'F',
        title: 'One last thing',
        questions: [
            {
                id: 'Q12_PRIORITY',
                type: 'single-select',
                category: 'Store Experience - priority',
                field: 'Store_Experience__c',
                text: 'If we could fix or add just ONE thing to make you shop with us more often, what would it be?',
                options: [
                    'More competitive prices',
                    'Better product quality and freshness',
                    'Better stock availability',
                    'Faster checkout',
                    'A cleaner, easier-to-navigate store',
                    'Wider product range',
                    'More food choices',
                    'Friendlier, more available staff',
                    "Nothing - I'm already happy"
                ],
                // The source sheet lists this as part of the same row as the
                // priority pick ("- [Optional] Tell us more"), not a separate
                // question - so it renders inline on this screen, the same
                // way "Other, please specify" does, rather than as its own step.
                optionalComment: {
                    id: 'Q12_COMMENT',
                    field: 'Store_Experience_Comments__c',
                    label: 'Tell us more (optional)'
                }
            },
            {
                id: 'Q13_OPEN',
                type: 'open-text',
                category: 'Open feedback',
                field: 'Open_Feedback__c',
                required: false,
                text: "Anything else you'd like to tell the Landers team?"
            }
        ]
    }
];