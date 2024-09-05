export const LandingPage = () => {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-r from-blue-500 to-purple-600 text-white">
      <h1 className="text-4xl font-bold mb-4">
        Welcome to Skia Poker and Texas Hold'em
      </h1>
      <p className="text-xl mb-8">
        Experience Texas Hold'em on the blockchain!
      </p>
      <button className="bg-yellow-400 text-black hover:bg-yellow-500 p-5">
        Connect Wallet
      </button>
    </div>
  );
};
