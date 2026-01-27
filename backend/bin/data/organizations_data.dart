const Map<String, List<Map<String, dynamic>>> organizationsData = {
  "United Nations (UN)": [
    {
      "question": "In which year was the United Nations established?",
      "options": ["1944", "1945", "1948", "1950"],
      "answer": "1945",
      "explanation": "The UN was founded on October 24, 1945, after World War II to maintain international peace."
    },
    {
      "question": "Where is the headquarters of the United Nations located?",
      "options": ["Geneva", "London", "Paris", "New York City"],
      "answer": "New York City",
      "explanation": "While the UN has offices in Geneva and Vienna, its primary headquarters is in New York City."
    },
    {
      "question": "Who is the current Secretary-General of the UN (as of 2024)?",
      "options": ["Ban Ki-moon", "Kofi Annan", "António Guterres", "Boutros Boutros-Ghali"],
      "answer": "António Guterres",
      "explanation": "António Guterres, a Portuguese politician, took office as Secretary-General in 2017."
    },
    {
      "question": "Which organ of the UN is responsible for maintaining international peace and security?",
      "options": ["General Assembly", "Security Council", "Secretariat", "Economic and Social Council"],
      "answer": "Security Council",
      "explanation": "The Security Council consists of 15 members, including 5 permanent members with veto power."
    },
    {
      "question": "How many permanent members are in the UN Security Council?",
      "options": ["5", "10", "15", "20"],
      "answer": "5",
      "explanation": "The permanent members (P5) are China, France, Russia, the UK, and the USA."
    },
    {
      "question": "The International Court of Justice is located in:",
      "options": ["New York", "Geneva", "The Hague", "Washington DC"],
      "answer": "The Hague",
      "explanation": "The ICJ is the only principal organ of the UN not located in New York; it is in the Netherlands."
    },
  ],
  "International Financial Orgs": [
    {
      "question": "Where is the headquarters of the World Bank?",
      "options": ["New York", "Washington D.C.", "Geneva", "London"],
      "answer": "Washington D.C.",
      "explanation": "The World Bank and the IMF are both headquartered in Washington D.C., USA."
    },
    {
      "question": "Which organization is known as the 'Lender of Last Resort' for countries?",
      "options": ["World Bank", "WTO", "IMF", "ADB"],
      "answer": "IMF",
      "explanation": "The International Monetary Fund (IMF) provides financial assistance to countries facing balance of payments problems."
    },
    {
      "question": "What is the main function of the World Trade Organization (WTO)?",
      "options": ["Poverty reduction", "Global health", "Regulating international trade", "Environmental protection"],
      "answer": "Regulating international trade",
      "explanation": "The WTO, based in Geneva, deals with the global rules of trade between nations."
    },
    {
      "question": "Where is the headquarters of the Asian Development Bank (ADB)?",
      "options": ["Tokyo", "Beijing", "Manila", "New Delhi"],
      "answer": "Manila",
      "explanation": "The ADB is headquartered in Mandaluyong, Metro Manila, Philippines."
    },
  ],
  "Global Alliances (NATO, BRICS, G20)": [
    {
      "question": "What does NATO stand for?",
      "options": ["North Atlantic Treaty Organization", "North Asian Trade Org", "National American Treaty Org", "Northern Alliance Trade Office"],
      "answer": "North Atlantic Treaty Organization",
      "explanation": "NATO is a military alliance established in 1949 between North American and European countries."
    },
    {
      "question": "Which country hosted the G20 Summit in 2023?",
      "options": ["Brazil", "India", "Indonesia", "South Africa"],
      "answer": "India",
      "explanation": "India held the G20 Presidency from December 2022 to November 2023, hosting the summit in New Delhi."
    },
    {
      "question": "The 'B' in BRICS stands for:",
      "options": ["Belgium", "Bangladesh", "Brazil", "Britain"],
      "answer": "Brazil",
      "explanation": "BRICS consists of Brazil, Russia, India, China, and South Africa (expanded in 2024)."
    },
    {
      "question": "Where is the headquarters of SAARC located?",
      "options": ["New Delhi", "Islamabad", "Kathmandu", "Dhaka"],
      "answer": "Kathmandu",
      "explanation": "The South Asian Association for Regional Cooperation (SAARC) secretariat is in Kathmandu, Nepal."
    },
    {
      "question": "The European Union (EU) uses which common currency?",
      "options": ["Pound", "Franc", "Euro", "Mark"],
      "answer": "Euro",
      "explanation": "The Euro is the official currency for 20 of the 27 EU member states (the Eurozone)."
    },
  ],
  "Indian National Organizations": [
    {
      "question": "Which organization is responsible for space research in India?",
      "options": ["DRDO", "ISRO", "BARC", "HAL"],
      "answer": "ISRO",
      "explanation": "The Indian Space Research Organisation (ISRO) is headquartered in Bengaluru."
    },
    {
      "question": "Who is the ex-officio chairman of NITI Aayog?",
      "options": ["President of India", "Finance Minister", "Prime Minister", "Vice President"],
      "answer": "Prime Minister",
      "explanation": "NITI Aayog replaced the Planning Commission in 2015, with the PM as its chairperson."
    },
    {
      "question": "SEBI is the regulator for which market in India?",
      "options": ["Insurance", "Banking", "Capital/Securities", "Telecom"],
      "answer": "Capital/Securities",
      "explanation": "The Securities and Exchange Board of India (SEBI) regulates the stock market."
    },
    {
      "question": "Where is the headquarters of the Reserve Bank of India (RBI)?",
      "options": ["New Delhi", "Mumbai", "Kolkata", "Chennai"],
      "answer": "Mumbai",
      "explanation": "While it was initially established in Kolkata, the RBI moved to Mumbai in 1937."
    },
    {
      "question": "DRDO is related to which field?",
      "options": ["Agriculture", "Defense Research", "Space Research", "Medical Research"],
      "answer": "Defense Research",
      "explanation": "The Defence Research and Development Organisation (DRDO) develops military technology."
    },
  ],
  "Specialized Agencies (WHO, UNESCO)": [
    {
      "question": "UNESCO is primarily concerned with:",
      "options": ["Health", "Environment", "Education, Science, and Culture", "Trade"],
      "answer": "Education, Science, and Culture",
      "explanation": "UNESCO works to build peace through international cooperation in these fields."
    },
    {
      "question": "Where is the headquarters of the World Health Organization (WHO)?",
      "options": ["Paris", "Rome", "Geneva", "Vienna"],
      "answer": "Geneva",
      "explanation": "The WHO is a specialized agency of the UN responsible for international public health."
    },
    {
      "question": "Which organization is responsible for children's welfare globally?",
      "options": ["UNHCR", "UNICEF", "UNDP", "UNESCO"],
      "answer": "UNICEF",
      "explanation": "The United Nations Children's Fund (UNICEF) provides humanitarian and developmental aid to children worldwide."
    },
    {
      "question": "The 'Interpol' is the international organization for:",
      "options": ["Environmental Protection", "Police Cooperation", "Postal Services", "Atomic Energy"],
      "answer": "Police Cooperation",
      "explanation": "Interpol facilitates worldwide police cooperation and crime control."
    }
  ]
};
