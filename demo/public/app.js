const handleResponse = (response) => {
  const target = document.getElementById("result");
  response.text().then((body) => {
    target.innerHTML = body;

    target.querySelector("svg").className = "ui fluid image";
  });
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

const submit = () => {
  if (!shouldSubmit()) {
    return;
  }

  const config = {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(dataFromForm()),
  };
  fetch("/", config).then(handleResponse);
};

const attachEvents = () => {
  const form = document.forms[0];
  const fields = ["pattern", "value"];

  fields.forEach((field) => form[field].addEventListener("keyup", submit));
  form.addEventListener("submit", () => false);
};

document.addEventListener("DOMContentLoaded", attachEvents);
document.addEventListener("DOMContentLoaded", submit);
