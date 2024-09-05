export const WaitingRoomPage = () => {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-800 text-white">
      <h2 className="text-3xl font-bold mb-4">Waiting for Opponent</h2>
      <div className="animate-spin rounded-full h-32 w-32 border-t-2 border-b-2 border-green-500 mb-4"></div>
      <p className="text-xl mb-8">Searching for a worthy opponent...</p>
      <button className="bg-red-500 hover:bg-red-600 p-3" onClick={() => {}}>
        Cancel
      </button>
    </div>
  );
};
