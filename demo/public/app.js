const results = {
  match: {
    icon: ["check", "circle"],
    text: "That's a match!",
    color: "teal",
  },
  noMatch: {
    icon: ["exclamation", "triangle"],
    text: "That's not a match!",
    color: "yellow",
  },
  notAnExpression: {
    icon: ["times", "circle"],
    text: "Invalid regular expression",
    color: "red",
  },
};

const colors = Object.keys(results).map((key) => results[key].color);
const icons = Object.keys(results)
  .map((key) => results[key].icon)
  .flat()
  .filter((value, index, self) => self.indexOf(value) === index);

const render = (result) => {
  const target = document.querySelector("div.ui.massive.label");
  const icon = target.querySelector("i");
  const text = target.querySelector("span");

  colors.forEach((name) => target.classList.remove(name));
  icons.forEach((name) => icon.classList.remove(name));

  target.classList.add(result.color);
  result.icon.forEach((name) => icon.classList.add(name));
  text.innerHTML = result.text;
};

const dataFromForm = () => {
  const form = document.forms[0];
  return {
    pattern: form.pattern.value,
    value: form.value.value,
  };
};

const shouldSubmit = () => {
  const data = dataFromForm();
  return data.pattern.trim().length > 0 && data.value.length > 0;
};

const handleResponse = (response) => {
  if (response.status !== 200) {
    return results.notAnExpression;
  }

  return response
    .json()
    .then((data) => {
      const result = data.match ? results.match : results.noMatch;
      render(result);
    })
    .catch(() => render(results.notAnExpression));
};

const submit = () => {
  if (!shouldSubmit()) {
    return;
  }

  const config = {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(dataFromForm()),
  };
  fetch("/", config).then(handleResponse).catch(handleResponse);
};

const attachEvents = () => {
  const form = document.forms[0];
  const fields = ["pattern", "value"];

  fields.forEach((field) => form[field].addEventListener("keyup", submit));
  form.addEventListener("submit", () => false);
};

document.addEventListener("DOMContentLoaded", attachEvents);
