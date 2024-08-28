import { useState } from "react";

export const Timer = () => {
  const [timeLeft, setTimeLeft] = useState(20);

  const timer = setInterval(function () {
    setTimeLeft((prev) => prev - 1);
    if (timeLeft <= 0) {
      clearInterval(timer);
    }
  }, 1000);
  return <div style={{ size: 20, padding: 5 }}>{timeLeft}</div>;
};
