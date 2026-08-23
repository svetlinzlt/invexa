export type Lang = "bg" | "en";

/**
 * Текстовете на двата езика, един до друг.
 *
 * Държат се заедно нарочно: така се вижда веднага, ако единият език изостане,
 * а страницата е малка и не оправдава библиотека за преводи.
 */
export type Copy = {
  lang: Lang;
  htmlLang: string;
  title: string;
  description: string;
  switchTo: { href: string; label: string };
  hero: { headline: string; accent: string; lead: string };
  plate: { amount: string; caption: string; from: string; today: string; to: string };
  what: {
    eyebrow: string;
    heading: string;
    lead: string;
    points: Array<{ title: string; body: string }>;
  };
  honest: {
    eyebrow: string;
    heading: string;
    lead: string;
    rows: Array<{ when: string; body: string }>;
  };
  price: { eyebrow: string; heading: string; lead: string };
  plans: {
    free: { name: string; price: string; per: string; features: string[]; pick: string };
    premium: { name: string; price: string; per: string; features: string[]; pick: string };
  };
  form: {
    chose: string;
    freeWord: string;
    premiumWord: string;
    prompt: string;
    placeholder: string;
    submit: string;
    sending: string;
    onlyEmail: string;
    doneNew: string;
    doneDuplicate: string;
    doneBody: string;
    doneChoice: string;
    doneFix: string;
    errorNetwork: string;
    errorGeneric: string;
  };
  footer: { body: string; writeTo: string };
};

export const BG: Copy = {
  lang: "bg",
  htmlLang: "bg",
  title: "Invexa — къде отидоха парите този месец",
  description:
    "Приложение за iPhone, което отговаря на един въпрос: как върви този месец. Влиза, излиза, остава — и къде точно отиде. В момента се строи.",
  switchTo: { href: "/en", label: "English" },
  hero: {
    headline: "Къде отидоха парите ти",
    accent: "този месец?",
    lead: "Приложение за iPhone, което отговаря на този въпрос за пет секунди. Колко е влязло, колко е излязло, колко остава — и къде точно отиде. Без методология, която трябва да учиш, и без таблици, които водиш на ръка.",
  },
  plate: {
    amount: "1 187,40",
    caption: "Похарчено\n21 от 31 дни",
    from: "1 АВГ",
    today: "ДНЕС · 21",
    to: "31 АВГ",
  },
  what: {
    eyebrow: "Какво прави",
    heading: "Месецът е целият продукт",
    lead: "Повечето приложения за лични финанси искат да те научат на система. Това иска само да ти покаже къде си, преди да е станало късно да промениш нещо.",
    points: [
      {
        title: "Един екран, един отговор",
        body: "Отваряш и виждаш влязло, излязло, остатък и къде отидоха парите. Без превъртане, без ровене в менюта.",
      },
      {
        title: "Заделеното не е похарчено",
        body: "Парите, които спестяваш или инвестираш, се броят отделно от разходите. Иначе картината лъже, а повечето прости тракери правят точно това.",
      },
      {
        title: "Записваш за три секунди",
        body: "От заключен телефон до записан разход: виджет, пряк път или „добави 12 евро обяд“ към Siri.",
      },
      {
        title: "Данните остават твои",
        body: "Живеят на телефона ти и в твоя iCloud. Няма регистрация, няма мой сървър, няма проследяване.",
      },
    ],
  },
  honest: {
    eyebrow: "Честно",
    heading: "Какво още го няма",
    lead: "Приложението се строи. Записвам хора сега, за да знам дали изобщо си струва да го довърша — затова предпочитам да си наясно какво липсва.",
    rows: [
      { when: "Днес", body: "Няма нищо за сваляне. Има дизайн, план и няколко седмици работа напред." },
      { when: "Първа версия", body: "Ръчно въвеждане, категории, повтарящи се плащания и сравнение по месеци. Внасяне на банково извлечение от файл." },
      { when: "По-късно", body: "Автоматично изтегляне от банката. Започва с една държава и се разширява само ако работи както трябва." },
      { when: "Най-накрая", body: "Инвестициите до разходите. Зависи от чужд интерфейс, който още е в бета, затова го обещавам последно." },
      { when: "Само за iPhone", body: "Няма да има версия за Android или за уеб. Ако това е спирачка за теб, по-добре да не се записваш." },
    ],
  },
  price: {
    eyebrow: "Цена",
    heading: "Кое от двете би избрал?",
    lead: "Още нищо не се плаща и нищо не се пуска сега. Избери варианта, който би ползвал — това е единственото, което ми показва дали цената е вярна.",
  },
  plans: {
    free: {
      name: "Безплатно",
      price: "0 €",
      per: "завинаги",
      features: [
        "Ръчно въвеждане без ограничение",
        "Месечен преглед и категории",
        "Повтарящи се плащания",
        "Синхронизация през твоя iCloud",
      ],
      pick: "Искам това →",
    },
    premium: {
      name: "Премиум",
      price: "4 €",
      per: "на месец",
      features: [
        "Всичко от безплатния план",
        "Автоматично изтегляне от банката",
        "Инвестиции на едно място с разходите",
        "Месечни прозрения и сравнения",
      ],
      pick: "Искам това →",
    },
  },
  form: {
    chose: "Избра",
    freeWord: "безплатния план",
    premiumWord: "премиум",
    prompt: "Остави имейл и ще те известя, когато има какво да пробваш.",
    placeholder: "име@поща.bg",
    submit: "Запиши ме",
    sending: "Записвам…",
    onlyEmail: "Само имейл, нищо друго. Без бюлетин, без препродаване на адреси. Отписваш се с един клик.",
    doneNew: "Записан си.",
    doneDuplicate: "Вече си в списъка — записът ти е тук.",
    doneBody: "Приложението още не е пуснато. Ще ти пиша веднъж, когато има какво да пробваш, и веднъж, ако проектът спре. Нищо друго.",
    doneChoice: "Отбеляза интерес към",
    doneFix: "Ако си сгрешил бутона, просто отговори на писмото.",
    errorNetwork: "Няма връзка със сървъра. Провери мрежата и опитай пак.",
    errorGeneric: "Записът не мина.",
  },
  footer: {
    body: "Invexa се строи в България за потребители в еврозоната. Числата в графиката горе са примерни. Имейлът ти се пази само за да те известя за този проект и се изтрива при поискване — пиши на ",
    writeTo: "hello@invexa.app",
  },
};

export const EN: Copy = {
  lang: "en",
  htmlLang: "en",
  title: "Invexa — where did the money go this month",
  description:
    "An iPhone app that answers one question: how is this month going. What came in, what went out, what's left — and exactly where it went. Currently being built.",
  switchTo: { href: "/", label: "Български" },
  hero: {
    headline: "Where did your money go",
    accent: "this month?",
    lead: "An iPhone app that answers that in five seconds. What came in, what went out, what's left — and exactly where it went. No methodology to learn, no spreadsheet to keep by hand.",
  },
  plate: {
    amount: "1,187.40",
    caption: "Spent\n21 of 31 days",
    from: "1 AUG",
    today: "TODAY · 21",
    to: "31 AUG",
  },
  what: {
    eyebrow: "What it does",
    heading: "The month is the whole product",
    lead: "Most personal finance apps want to teach you a system. This one only wants to show you where you stand, while there's still time to change something.",
    points: [
      {
        title: "One screen, one answer",
        body: "Open it and see what came in, what went out, what's left and where it went. No scrolling, no digging through menus.",
      },
      {
        title: "Money set aside isn't spent",
        body: "What you save or invest is counted separately from spending. Otherwise the picture lies — and most simple trackers do exactly that.",
      },
      {
        title: "Three seconds to log it",
        body: "From locked phone to recorded expense: a widget, a shortcut, or “add 12 euros lunch” to Siri.",
      },
      {
        title: "Your data stays yours",
        body: "It lives on your phone and in your iCloud. No account, no server of mine, no tracking.",
      },
    ],
  },
  honest: {
    eyebrow: "Honestly",
    heading: "What isn't there yet",
    lead: "The app is being built. I'm collecting names now to find out whether it's worth finishing — so I'd rather you knew what's missing.",
    rows: [
      { when: "Today", body: "There is nothing to download. There's a design, a plan, and several weeks of work ahead." },
      { when: "First version", body: "Manual entry, categories, recurring payments and month-to-month comparison. Bank statement import from a file." },
      { when: "Later", body: "Automatic bank sync. It starts with one country and expands only if it works properly." },
      { when: "Last of all", body: "Investments next to spending. It depends on someone else's API that is still in beta, so I promise it last." },
      { when: "iPhone only", body: "There will be no Android or web version. If that's a dealbreaker, better not to sign up." },
    ],
  },
  price: {
    eyebrow: "Price",
    heading: "Which of the two would you pick?",
    lead: "Nothing is charged and nothing launches now. Pick the one you'd actually use — that's the only thing that tells me whether the price is right.",
  },
  plans: {
    free: {
      name: "Free",
      price: "€0",
      per: "forever",
      features: [
        "Unlimited manual entry",
        "Monthly overview and categories",
        "Recurring payments",
        "Sync through your own iCloud",
      ],
      pick: "I'd pick this →",
    },
    premium: {
      name: "Premium",
      price: "€4",
      per: "per month",
      features: [
        "Everything in the free plan",
        "Automatic bank sync",
        "Investments alongside spending",
        "Monthly insights and comparisons",
      ],
      pick: "I'd pick this →",
    },
  },
  form: {
    chose: "You picked",
    freeWord: "the free plan",
    premiumWord: "premium",
    prompt: "Leave an email and I'll tell you when there's something to try.",
    placeholder: "name@example.com",
    submit: "Add me",
    sending: "Saving…",
    onlyEmail: "Just an email, nothing else. No newsletter, no selling addresses. One click to unsubscribe.",
    doneNew: "You're on the list.",
    doneDuplicate: "You were already on the list — your entry is here.",
    doneBody: "The app hasn't launched. I'll write once when there's something to try, and once if the project stops. Nothing else.",
    doneChoice: "You showed interest in",
    doneFix: "If you hit the wrong button, just reply to the email.",
    errorNetwork: "No connection to the server. Check your network and try again.",
    errorGeneric: "That didn't save.",
  },
  footer: {
    body: "Invexa is being built in Bulgaria for people across the eurozone. The figures in the chart above are examples. Your email is kept only to tell you about this project and is deleted on request — write to ",
    writeTo: "hello@invexa.app",
  },
};

export const COPY: Record<Lang, Copy> = { bg: BG, en: EN };
