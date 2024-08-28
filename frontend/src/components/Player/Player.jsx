import "./player.scss";

// eslint-disable-next-line react/prop-types
export const Player = ({ name, cards = [], role }) => {
  return (
    <div className="player">
      <div className="player__cards">
        {cards?.map((card) => (
          <div key={card} className="player__card"></div>
        ))}
      </div>
      <div className="player__wrapper">
        <div className="player__img">
          <img src="../../assets/boy.svg" />
        </div>
        <div className="player__name" style={{ backgroundColor: "white" }}>
          {name}
        </div>
        <div className="player__name" style={{ backgroundColor: "white" }}>
          {role}
        </div>
      </div>
    </div>
  );
};
