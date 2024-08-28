import "./community.scss";

// eslint-disable-next-line react/prop-types
export const CommunityCards = ({ cards = ["df", "ff"] }) => {
  return (
    <div className="community">
      {cards?.map((card) => (
        <div
          key={card}
          style={{
            width: 20,
            height: 40,
            border: "1px solid",
            backgroundColor: "white",
          }}
        >
          {card}
        </div>
      ))}
    </div>
  );
};
