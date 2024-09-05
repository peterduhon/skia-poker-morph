import { useNavigate } from "react-router-dom";

export const GameModePage = () => {
  const navigate = useNavigate();

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-800 text-white">
      <h2 className="text-3xl font-bold mb-8">Choose Game Mode</h2>
      <div className="space-y-4">
        <button
          className="w-48 bg-green-500 hover:bg-green-600"
          onClick={() => {
            navigate("/wroom");
          }}
        >
          Play vs Player
        </button>
        <button
          className="w-48 bg-blue-500 hover:bg-blue-600"
          onClick={() => {}}
        >
          Play vs AI
        </button>
      </div>
    </div>
  );
};
