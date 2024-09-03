import React from "react";
import { motion } from "framer-motion";

const PokerTable = () => {
  const playerPositions = [
    { angle: 90, label: "Player 1" },
    { angle: 126, label: "Player 2" },
    { angle: 162, label: "Player 3" },
    { angle: 198, label: "Player 4" },
    { angle: 234, label: "Player 5" },
    { angle: 270, label: "Player 6" },
    { angle: 306, label: "Player 7" },
    { angle: 342, label: "Player 8" },
    { angle: 18, label: "Player 9" },
    { angle: 54, label: "Player 10" },
  ];

  return (
    <div className="min-h-screen w-full bg-[#1C0F00] flex justify-center items-center p-4">
      <div className="relative w-full max-w-[800px] aspect-square">
        {/* Background elements */}
        <div className="absolute inset-0 bg-[url('/textures/aged-parchment.jpg')] opacity-10 rounded-full"></div>
        <motion.div
          className="absolute inset-0 bg-[url('/textures/smoke.png')] bg-repeat rounded-full"
          animate={{ backgroundPosition: ["0% 0%", "100% 100%"] }}
          transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
        ></motion.div>

        {/* Poker table */}
        <motion.div
          className="absolute inset-0 bg-[#36454F] rounded-full"
          style={{
            boxShadow:
              "0 0 50px rgba(184, 115, 51, 0.3), inset 0 0 30px rgba(184, 115, 51, 0.5)",
            backgroundImage: 'url("/textures/wood-grain.jpg")',
          }}
          animate={{ rotate: 360 }}
          transition={{ duration: 200, repeat: Infinity, ease: "linear" }}
        >
          {/* Community Cards */}
          <div className="absolute top-1/4 left-1/2 transform -translate-x-1/2 flex space-x-1 md:space-x-2">
            {[1, 2, 3, 4, 5].map((i) => (
              <motion.div
                key={i}
                className="w-[12%] aspect-[2/3] bg-[#C0C0C0] rounded-lg shadow-lg"
                whileHover={{ scale: 1.1 }}
                style={{ backgroundImage: 'url("/textures/card-back.jpg")' }}
              ></motion.div>
            ))}
          </div>

          {/* Player positions */}
          {playerPositions.map((player, index) => {
            const radians = (player.angle - 90) * (Math.PI / 180);
            const x = 50 + 40 * Math.cos(radians);
            const y = 50 + 40 * Math.sin(radians);

            return (
              <motion.div
                key={index}
                className="absolute w-[15%] aspect-square bg-[#800000] rounded-full flex justify-center items-center"
                style={{
                  left: `${x}%`,
                  top: `${y}%`,
                  transform: "translate(-50%, -50%)",
                  boxShadow: "0 0 10px rgba(176, 0, 0, 0.7)",
                }}
                whileHover={{ scale: 1.1 }}
              >
                <p className="text-[#C0C0C0] text-[0.6em] md:text-xs font-['Orbitron']">
                  {player.label}
                </p>
              </motion.div>
            );
          })}

          {/* Mystical symbols */}
          <div className="absolute inset-0 pointer-events-none">
            <img
              src="/symbols/rune1.png"
              className="absolute top-1/4 left-1/4 w-[8%] opacity-30"
            />
            <img
              src="/symbols/rune2.png"
              className="absolute top-1/4 right-1/4 w-[8%] opacity-30"
            />
            <img
              src="/symbols/rune3.png"
              className="absolute bottom-1/4 left-1/4 w-[8%] opacity-30"
            />
            <img
              src="/symbols/rune4.png"
              className="absolute bottom-1/4 right-1/4 w-[8%] opacity-30"
            />
          </div>
        </motion.div>

        {/* Neon accents */}
        <div className="absolute inset-0 pointer-events-none">
          <motion.div
            className="absolute top-0 left-1/2 w-[1%] h-1/3 bg-[#B22222]"
            animate={{ opacity: [0.5, 1, 0.5] }}
            transition={{ duration: 2, repeat: Infinity }}
          ></motion.div>
          <motion.div
            className="absolute bottom-0 left-1/2 w-[1%] h-1/3 bg-[#B22222]"
            animate={{ opacity: [0.5, 1, 0.5] }}
            transition={{ duration: 2, repeat: Infinity, delay: 1 }}
          ></motion.div>
        </div>
      </div>
    </div>
  );
};

export default PokerTable;
